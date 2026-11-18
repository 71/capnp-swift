/// A non-null pointer to a struct, list, or capability stored in a `Message`.
public struct AnyPointer {
  private(set) public var unsafePointer: UnsafeMessagePointer

  public init(unsafePointer: UnsafeMessagePointer) {
    self.unsafePointer = unsafePointer
  }

  /// Yields `nil` if the pointer is null, or the pointer itself if it is not.
  public var orNil: AnyPointer? { read() == 0 ? nil : self }

  // ---------------------------------------------------------------------------------------------
  // MARK: Resolve

  /// Parses a pointer to the struct, list, or capability it points to, resolving far pointers.
  ///
  /// Returns `nil` if the pointer is null.
  public func resolve() throws(PointerError) -> ResolvedPointer? {
    guard unsafePointer.traversalLimit > 0 else {
      throw .traversalLimitExceeded
    }

    let withLowerTraversalLimit = UnsafeMessagePointer(
      message: unsafePointer.message,
      segmentIndex: unsafePointer.segmentIndex,
      pointer: unsafePointer.pointer,
      traversalLimit: unsafePointer.traversalLimit - 1,
      readOnly: unsafePointer.isReadOnly
    )

    return try AnyPointer(unsafePointer: withLowerTraversalLimit)
      .resolveIgnoringTraversalLimit()
  }

  /// Resolves the pointer without checking the traversal limit.
  ///
  /// Returns `nil` if the pointer is null.
  public func resolveIgnoringTraversalLimit() throws(PointerError) -> ResolvedPointer? {
    let word = read()

    if (word & 0b11) == 2 {
      // A (2 bits) = 2, to indicate that this is a far pointer.
      return try resolveFarPointer(word: word)
    } else if word != 0 {
      return try resolveIntraSegment(word: word)
    } else {
      return nil
    }
  }

  /// Resolves an intra-segment pointer encoded in `word`.
  private func resolveIntraSegment(word: Word) throws(PointerError) -> ResolvedPointer {
    if (word & 0b11) == 3 {
      // A (2 bits) = 3, to indicate that this is an "other" pointer.
      // B (30 bits) = 0, to indicate that this is a capability pointer.
      //
      // Check B before it is interpreted as an offset below, which would add 1 to it.
      guard readUInt32(in: word, atBit: 2, bitWidth: 30) == 0 else {
        throw .unknownPointerType
      }
    }

    // We can read the same offset for all intra-segment pointers, as they either start with
    // a 30-bit signed offset (struct, list) or an expected value (capability).
    let rawOffsetWords = Int(readInt32(in: word, atBit: 2, bitWidth: 30))

    guard rawOffsetWords != -1 else {
      // We would enter an infinite loop trying to resolve this pointer.
      if word == zeroSizedStruct {
        // Never mind, it's a zero-sized struct.
        return .struct(.init())
      }
      throw .traversalLimitExceeded
    }

    // +1 as the offset is relative to the end of the pointer.
    let offsetWords = try rawOffsetWords.add(1, orThrow: PointerError.pointerOutOfRange)

    return try resolveIntraSegment(
      type: UInt8(word & 0b11),
      offsetWords: offsetWords,
      data: UInt32(word >> 32)
    )
  }

  /// Resolves an intra-segment pointer given its type A (2 bits), its offset (30 bits), and its
  /// data (32 bits).
  private func resolveIntraSegment(type: UInt8, offsetWords: Int, data: UInt32)
    throws(PointerError) -> ResolvedPointer
  {
    switch type {
    // A (2 bits) = 0, to indicate that this is a struct pointer.
    case 0:
      let (dataSectionWords, pointerSectionWords) = decodeStructPointer(data)

      // Validate pointer.
      try checkPointerRange(
        offsetWords: offsetWords,
        words: UInt32(dataSectionWords) + UInt32(pointerSectionWords)
      )

      let dataBytes = try UInt32(dataSectionWords).multiplied(
        by: 8,
        orThrow: PointerError.sizeOverflow
      )

      return .struct(
        .init(
          data: unsafePointer.advanced(
            byBytes: try offsetWords.wordsToBytes(
              orThrow: PointerError.pointerOutOfRange
            )
          ),
          size: try .init(dataBytes: dataBytes, pointers: pointerSectionWords)
        )
      )

    // A (2 bits) = 1, to indicate that this is a list pointer.
    case 1:
      // C (3 bits) = Size of each element: [...]
      let elementSize = ListElementSize.Raw.init(sizeBits: UInt8(data & 0b111))!

      // D (29 bits) = Size of the list: [...]
      let listSize = data >> 3

      if let bits = elementSize.bits {
        // when C <> 7: Number of elements in the list.

        // Validate pointer.
        let neededBits = UInt64(listSize) * UInt64(bits)
        let neededWords = UInt32(neededBits.divideRoundingUp(by: 64))

        try checkPointerRange(
          offsetWords: offsetWords,
          words: neededWords
        )

        // We don't use `advanced(byWords:)` since it accepts `UInt32`s, but here we may
        // have a negative offset.
        let offsetBytes = try offsetWords.wordsToBytes(
          orThrow: PointerError.pointerOutOfRange
        )

        return .list(
          .init(
            data: unsafePointer.advanced(byBytes: offsetBytes),
            elementSize: .init(rawValue: elementSize)!,
            count: listSize
          )
        )
      }

      // when C = 7: Number of words in the list, not counting the tag word (see below).

      // Validate pointer. `listSize` fits in 29 bits, so this cannot overflow.
      try checkPointerRange(offsetWords: offsetWords, words: listSize + 1)

      let offsetBytes = try offsetWords.wordsToBytes(
        orThrow: PointerError.pointerOutOfRange
      )

      // Read the tag word.
      let tagWord = unsafePointer.pointer.loadLe(fromByteOffset: offsetBytes, as: Word.self)

      guard (tagWord & 0b11) == 0 else {
        throw .invalidCompositeList
      }

      let elementCount = readUInt32(in: tagWord, atBit: 2, bitWidth: 30)
      let (dataSectionWords, pointerSectionWords) = decodeStructPointer(UInt32(tagWord >> 32))

      let compositeSize = try StructSize(
        dataBytes: UInt32(widen: dataSectionWords, multipliedBy: 8),
        pointers: pointerSectionWords
      )

      // Widen to `UInt64`, as the product can overflow `UInt32`.
      guard
        (UInt64(dataSectionWords) + UInt64(pointerSectionWords)) * UInt64(elementCount)
          == UInt64(listSize)
      else {
        throw .invalidCompositeList
      }

      let fullOffsetBytes = try offsetBytes.add(8, orThrow: PointerError.sizeOverflow)  // +8 to skip the tag word.

      return .list(
        .init(
          data: unsafePointer.advanced(byBytes: fullOffsetBytes),
          compositeSize: compositeSize,
          count: elementCount
        )
      )

    // A (2 bits) = 3, to indicate that this is an "other" pointer.
    case 3:
      // B (30 bits) = 0, to indicate that this is a capability pointer. Callers check B, as
      // `offsetWords` is derived from it differently for intra-segment and double-far pointers.
      //
      // C (32 bits) = Index of the capability in the message's capability table.
      return .capability(.init(capabilityIndex: data))

    default:
      fatalError()
    }
  }

  /// Resolves a far pointer encoded in `word`.
  private func resolveFarPointer(word: Word) throws(PointerError) -> ResolvedPointer {
    // B (1 bit) = 0 if the landing pad is one word, 1 if it is two words.
    let isOneWord = (word >> 2) & 1 == 0

    // C (29 bits) = Offset, in words, from the start of the target segment to the location
    // of the far-pointer landing-pad within that segment.
    let landingPadOffset = readUInt32(in: word, atBit: 3, bitWidth: 29)

    // D (32 bits) = ID of the target segment.
    let targetSegmentId = UInt32(word >> 32)

    // Validate the segment ID.
    guard targetSegmentId < unsafePointer.message.segments.count else {
      throw .segmentOutOfRange
    }
    let targetSegment = unsafePointer.message.segments[Int(targetSegmentId)]

    // Validate the landing pad offset.
    let landingPadLength = UInt32(isOneWord ? 1 : 2)

    // Landing pad offset is made up of 29 bits, so we can't overflow.
    guard landingPadOffset + landingPadLength <= targetSegment.words else {
      throw .pointerOutOfRange
    }

    // Get the landing pad pointer.
    let landingPadWord = targetSegment.rawPointer.loadLe(
      fromByteOffset: try landingPadOffset.wordsToBytes(orThrow: PointerError.sizeOverflow),
      as: Word.self
    )

    // Resolve the landing pad pointer.
    if isOneWord {
      // This is a normal pointer; it cannot be a far pointer.
      guard (landingPadWord & 0b11) != 2 else {
        throw .invalidFarPointer
      }

      let targetPointer = UnsafeMessagePointer(
        message: unsafePointer.message,
        segmentIndex: targetSegmentId,
        pointer: targetSegment.rawPointer.advanced(
          by: try landingPadOffset.wordsToBytes(orThrow: PointerError.sizeOverflow)
        ),
        traversalLimit: unsafePointer.traversalLimit,
        readOnly: unsafePointer.isReadOnly
      )

      return try AnyPointer(unsafePointer: targetPointer).resolveIntraSegment(
        word: landingPadWord
      )
    }

    // The landing pad is a far pointer with B == 0.
    guard (landingPadWord & 0b111) == 0b010 else {
      throw .invalidFarPointer
    }

    let contentOffsetWords = readUInt32(in: landingPadWord, atBit: 3, bitWidth: 29)
    let secondTargetSegmentId = UInt32(landingPadWord >> 32)

    // Get the tag word.
    let tagWord = targetSegment.rawPointer.loadLe(
      fromByteOffset: try Int(fromUInt32: landingPadOffset + 1, multipliedBy: 8),
      as: Word.self
    )

    // Validate the tag word.
    guard (tagWord & 0b11) != 2 else {
      // It's a far pointer, but it should be an intra-segment pointer.
      throw .invalidFarPointer
    }
    guard readUInt32(in: tagWord, atBit: 2, bitWidth: 30) == 0 else {
      // Its offset must be zero.
      throw .invalidFarPointer
    }

    // Validate the second segment ID.
    guard secondTargetSegmentId < unsafePointer.message.segments.count else {
      throw .segmentOutOfRange
    }
    let secondTargetSegment = unsafePointer.message.segments[Int(secondTargetSegmentId)]

    // Validate the content offset.
    guard contentOffsetWords < secondTargetSegment.words else {
      throw .pointerOutOfRange
    }

    let targetPointer = UnsafeMessagePointer(
      message: unsafePointer.message,
      segmentIndex: secondTargetSegmentId,
      // Do not advance the pointer, as this is done by `resolveIntraSegment()`.
      pointer: secondTargetSegment.rawPointer,
      traversalLimit: unsafePointer.traversalLimit,
      readOnly: unsafePointer.isReadOnly
    )

    return try AnyPointer(unsafePointer: targetPointer).resolveIntraSegment(
      type: UInt8(tagWord & 0b11),
      offsetWords: Int(contentOffsetWords),
      data: UInt32(truncatingIfNeeded: tagWord >> 32)
    )
  }

  // ---------------------------------------------------------------------------------------------
  // MARK: Initialize

  /// Initializes a struct, updating the pointer.
  internal func initStruct(size: StructSize) -> StructPointer {
    // C (16 bits) only fits data sections of up to 2^16 - 1 words.
    precondition(size.dataWords <= UInt16.max, "struct data section is too large")

    let pointer = allocatePointer(
      words: size.sizeInWords,
      isList: false,
      // C (16 bits) = Size of the struct's data section, in words.
      // D (16 bits) = Size of the struct's pointer section, in words.
      data: size.dataWords | (UInt32(size.pointers) << 16)
    )

    return StructPointer(data: pointer, size: size)
  }

  /// Initializes a list, updating the pointer. Returns `nil` if `count` elements of the given
  /// size cannot be encoded in a list pointer.
  internal func initList(count: UInt32, elementSize: ListElementSize) -> ListPointer? {
    if case .composite(let structSize) = elementSize {
      return initList(count: count, structSize: structSize)
    }

    // D (29 bits) = Size of the list: when C <> 7: Number of elements in the list.
    guard count < (1 << 29) else { return nil }

    let totalBits = UInt64(elementSize.bits) * UInt64(count)
    let totalWords = UInt32(totalBits.divideRoundingUp(by: 64))

    let pointer = allocatePointer(
      words: totalWords,
      isList: true,
      // C (3 bits) = Size of each element: [...]
      // D (29 bits) = Size of the list:
      //   when C <> 7: Number of elements in the list.
      data: UInt32(elementSize.rawValue.rawValue) | (UInt32(count) << 3)
    )

    return ListPointer(
      data: pointer,
      elementSize: elementSize,
      count: count
    )
  }

  /// Initializes a list, updating the pointer. Returns `nil` if `count` elements of the given
  /// size cannot be encoded in a list pointer.
  internal func initList(count: UInt32, structSize: StructSize) -> ListPointer? {
    // The tag word stores the element count in 30 bits, and the list pointer stores the number
    // of words (excluding the tag) in 29 bits.
    let words64 = UInt64(structSize.sizeInWords) * UInt64(count)

    guard count < (1 << 30), words64 < (1 << 29) else { return nil }

    let words = UInt32(words64)
    let pointer = allocatePointer(
      words: words + 1,  // +1 for the tag word.
      isList: true,
      // C (3 bits) = Size of each element:
      //  7 = composite (see below)
      // D (29 bits) = Size of the list:
      //  when C = 7: Number of words in the list, not counting the tag word
      data: 7 | (words << 3)
    )

    // Write the tag word.
    //
    // A (2 bits) = 0, to indicate that this is a struct pointer.
    // B (30 bits) = the number of elements in the list.
    // C (16 bits) = Size of the struct's data section, in words.
    // D (16 bits) = Size of the struct's pointer section, in words.
    //
    // > The tag has the same layout as a struct pointer, except that the pointer offset (B)
    // > instead indicates the number of elements in the list.
    let tagWord: Word =
      (Word(count) << 2)
      | (Word(structSize.dataWords) << 32)
      | (Word(structSize.pointers) << 48)

    pointer.assertMutablePointer.storeBytes(of: tagWord.littleEndian, as: Word.self)

    return ListPointer(
      data: try! pointer.advanced(byWords: 1),
      compositeSize: structSize,
      count: count
    )
  }

  /// Allocates memory to store the given number of words for a list or struct, updating the
  /// pointer. `data` are the last 32 bits of the list or struct pointer.
  private func allocatePointer(words: UInt32, isList: Bool, data: UInt32)
    -> UnsafeMessagePointer
  {
    assert(!unsafePointer.isReadOnly)

    if !isList && words == 0 && data == 0 {
      write(word: zeroSizedStruct)

      return unsafePointer
    }

    let typeBits = Word(isList ? 1 : 0)

    if let newPointer = unsafePointer.message.tryAllocate(
      words: words,
      in: unsafePointer.segmentIndex
    ) {
      // If the pointer is in the same segment, we can write it directly.
      let offsetBytes = unsafePointer.pointer.distance(to: newPointer.pointer)
      let offsetWords = Word(offsetBytes / 8)
      let offsetBits = (offsetWords - 1) << 2

      write(word: typeBits | offsetBits | (Word(data) << 32))

      return newPointer
    }

    // We need to use another segment for the data. We'll write a far pointer landing pad, so
    // we need to allocate an additional word.
    let newPointer = unsafePointer.message.allocate(words: words + 1)
    let offsetBits = Word(0)

    // Write the landing pad.
    newPointer.assertMutablePointer.storeBytes(
      of: (typeBits | offsetBits | (Word(data) << 32)).littleEndian,
      as: Word.self
    )

    // We don't support orphans (and don't form pointers to previously allocated data), so we
    // don't need to handle double indirections.
    let farPointerTypeBits = Word(2)
    let offsetWords = Word(newPointer.wordOffset)

    precondition(offsetWords < (1 << 29), "landing pad offset does not fit in a far pointer")

    // Write the pointer itself.
    //
    // A (2 bits) = 2, to indicate that this is a far pointer.
    // B (1 bit) = 0, as the landing pad is one word.
    // C (29 bits) = Offset, in words, of the landing pad within the target segment.
    // D (32 bits) = ID of the target segment.
    write(word: farPointerTypeBits | (offsetWords << 3) | (Word(newPointer.segmentIndex) << 32))

    return newPointer.advanced(byBytes: 8)  // Skip the landing pad word.
  }
}

extension AnyPointer: Freezable {
  public func asReadOnly() -> AnyPointer {
    .init(unsafePointer: unsafePointer.asReadOnly())
  }

  public mutating func freeze() -> Frozen<AnyPointer> {
    .init(unsafeFrozen: .init(unsafePointer: unsafePointer.freeze().value))
  }
}

// -------------------------------------------------------------------------------------------------
// MARK: ResolvedPointer

/// The resolved value of `AnyPointer`.
public enum ResolvedPointer {
  case capability(AnyCapability)
  case list(ListPointer)
  case `struct`(StructPointer)

  public func expectStruct() throws(PointerError) -> StructPointer {
    guard case .struct(let value) = self else {
      throw .unexpectedPointerType
    }
    return value
  }

  public func expectList() throws(PointerError) -> ListPointer {
    guard case .list(let value) = self else {
      throw .unexpectedPointerType
    }
    return value
  }

  public func expectCapability() throws(PointerError) -> AnyCapability {
    guard case .capability(let value) = self else {
      throw .unexpectedPointerType
    }
    return value
  }
}

// -------------------------------------------------------------------------------------------------
// MARK: PointerError

/// An error encountered while decoding or dereferencing a pointer.
public enum PointerError: Error {
  case segmentOutOfRange
  case pointerOutOfRange
  case traversalLimitExceeded
  case unknownPointerType
  case invalidCompositeList
  case invalidFarPointer
  case unexpectedPointerType
  case sizeOverflow
}

extension PointerError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .segmentOutOfRange:
      return "Segment out of range"
    case .pointerOutOfRange:
      return "Pointer out of range"
    case .traversalLimitExceeded:
      return "Traversal limit exceeded"
    case .unknownPointerType:
      return "Unknown pointer type"
    case .invalidCompositeList:
      return "Invalid composite list"
    case .invalidFarPointer:
      return "Invalid far pointer"
    case .unexpectedPointerType:
      return "Unexpected pointer type"
    case .sizeOverflow:
      return "Struct size is too large on this platform"
    }
  }
}

// -------------------------------------------------------------------------------------------------
// MARK: Helpers

/// The `Word` representing a pointer to a zero-sized struct.
///
/// > To encode a struct of zero size, set A, C, and D to zero, and set B (the offset) to -1.
///
/// That is `0x0000_0000_FFFF_FFFC`: shifting must happen on 32 bits so that the data and pointer
/// section sizes (bits 32 and above) stay zero.
private let zeroSizedStruct: Word = .init(UInt32.max << 2)

/// Decodes the last 32 bits of a struct pointer into its data and pointer section sizes.
private func decodeStructPointer(_ data: UInt32) -> (
  dataSectionWords: UInt16, pointerSectionWords: UInt16
) {
  // C (16 bits) = Size of the struct's data section, in words.
  let dataSectionWords = UInt16(truncatingIfNeeded: data)

  // D (16 bits) = Size of the struct's pointer section, in words.
  let pointerSectionWords = UInt16(truncatingIfNeeded: data >> 16)

  return (dataSectionWords, pointerSectionWords)
}

extension AnyPointer {
  /// Reads the pointer value.
  internal func read() -> Word {
    unsafePointer.pointer.loadLe(as: Word.self)
  }

  /// Writes the pointer value.
  internal func write(word: Word) {
    unsafePointer.assertMutablePointer.storeBytes(of: word.littleEndian, as: Word.self)
  }

  /// Writes the capability at the given pointer index.
  internal func writeCapability(capabilityIndex: UInt32) {
    // A (2 bits) = 3, to indicate that this is an "other" pointer.
    // B (30 bits) = 0, to indicate that this is a capability pointer.
    // C (32 bits) = Index of the capability in the message's capability table.
    let word = 0b11 | (Word(capabilityIndex) << 32)

    write(word: word)
  }

  /// Returns whether the at pointer relative to `raw` is in range.
  private func checkPointerRange(offsetWords: Int, words: UInt32) throws(PointerError) {
    // `offsetWords` may be negative, so we must check both ends of the range.
    let startWord = Int(unsafePointer.wordOffset) + offsetWords

    guard
      startWord >= 0,
      let endWord = UInt32(exactly: startWord + Int(words)),
      endWord <= unsafePointer.message.segments[Int(unsafePointer.segmentIndex)].words
    else {
      throw PointerError.pointerOutOfRange
    }
  }
}
