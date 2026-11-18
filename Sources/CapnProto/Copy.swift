extension AnyPointer {
  /// Performs a copy of the pointer and the data it points to, returning a new `AnyPointer` that
  /// points to the root of a new `Message`.
  public func copy() throws(PointerError) -> AnyPointer {
    let messageWords = try computeWordSize()
    let message = Message(withInitialWordCapacity: messageWords)

    try message.rootPointer.copy(from: self)

    assert(message.segmentCount == 1)
    assert(message.firstSegment.data.words == messageWords)

    return message.rootPointer
  }

  package func copy(from pointer: AnyPointer) throws(PointerError) {
    switch try pointer.resolve() {
    case nil:
      break
    case .capability(let capability):
      writeCapability(capabilityIndex: capability.capabilityIndex)

    case .list(let list):
      // Lists read from a message always have an encodable size.
      guard let target = initList(count: list.rawCount, elementSize: list.elementSize) else {
        throw .sizeOverflow
      }
      try target.copy(from: list)

    case .struct(let struct_):
      try initStruct(size: struct_.size).copy(from: struct_)
    }
  }

  /// Computes the size of the pointer (and the data it points to) in words, assuming a single
  /// segment (no far pointers).
  fileprivate func computeWordSize() throws(PointerError) -> UInt32 {
    let contentWords: UInt32 =
      switch try resolve() {
      case nil, .capability: 0
      case .list(let list): try list.computeContentWordSize()
      case .struct(let struct_): try struct_.computeContentWordSize()
      }

    return try contentWords.add(1, orThrow: PointerError.sizeOverflow)  // The pointer itself.
  }
}

extension List {
  /// Performs a copy of the list and the data it points to, returning a new `List` that points to
  /// the root of a new `Message`.
  public func copy() throws(PointerError) -> List<T> {
    .init(unchecked: try list$.copy())
  }
}

extension ListPointer {
  /// Performs a copy of the list and the data it points to, returning a new `ListPointer` that
  /// points to the root of a new `Message`.
  public func copy() throws(PointerError) -> ListPointer {
    // +1 for the root pointer.
    let messageWords = try computeContentWordSize().add(1, orThrow: PointerError.sizeOverflow)
    let message = Message(withInitialWordCapacity: messageWords)
    guard let copy = message.rootPointer.initList(count: rawCount, elementSize: elementSize) else {
      throw .sizeOverflow
    }

    try copy.copy(from: self)

    assert(message.segmentCount == 1)
    assert(message.firstSegment.data.words == messageWords)

    return copy
  }

  package func copy(from list: ListPointer) throws(PointerError) {
    switch list.elementSize {
    case .zero:
      break
    case .oneBit:
      copy(from: list, bitsPerElement: 1)
    case .oneByte:
      copy(from: list, bitsPerElement: 8)
    case .twoBytes:
      copy(from: list, bitsPerElement: 16)
    case .fourBytes:
      copy(from: list, bitsPerElement: 32)
    case .eightBytes:
      copy(from: list, bitsPerElement: 64)

    case .pointer:
      for i in 0..<list.count {
        let source: AnyPointer = try list.read(at: i)
        let target: AnyPointer = try read(at: i)

        try target.copy(from: source)
      }

    case .composite(let size):
      for i in 0..<list.count {
        let sourcePointer = list.data.advanced(byBytes: i * size.sizeInBytes)
        let source = StructPointer(data: sourcePointer, size: size)
        let target = initStruct(at: i)!

        try target.copy(from: source)
      }
    }
  }

  private func copy(from list: ListPointer, bitsPerElement: UInt32) {
    data.assertMutablePointer.copyMemory(
      from: list.data.pointer,
      // Widen to `Int` first, as the product may not fit in `UInt32`.
      byteCount: (Int(list.rawCount) * Int(bitsPerElement)).divideRoundingUp(by: 8)
    )
  }

  /// Computes the size of the list's content (excluding the pointer to it) in words, assuming a
  /// single segment (no far pointers).
  fileprivate func computeContentWordSize() throws(PointerError) -> UInt32 {
    switch elementSize {
    case .zero: return 0
    case .oneBit: return rawCount.divideRoundingUp(by: 64)
    case .oneByte: return rawCount.divideRoundingUp(by: 8)
    case .twoBytes: return rawCount.divideRoundingUp(by: 4)
    case .fourBytes: return rawCount.divideRoundingUp(by: 2)
    case .eightBytes: return rawCount

    case .pointer:
      var words: UInt32 = 0

      for i in 0..<count {
        // Each element's size includes its pointer, i.e. its slot in the list.
        words = try words.add(pointer(at: i).computeWordSize(), orThrow: PointerError.sizeOverflow)
      }

      return words

    case .composite(let size):
      var words: UInt32 = 1  // Tag word.

      for i in 0..<count {
        let struct_ = StructPointer(
          data: data.advanced(byBytes: i * size.sizeInBytes),
          size: size
        )

        // Structs are stored inline, so there is no pointer to count.
        words = try words.add(
          struct_.computeContentWordSize(),
          orThrow: PointerError.sizeOverflow
        )
      }

      return words
    }
  }
}

extension Struct {
  /// Performs a copy of the struct and the data it points to, returning a new `Struct` that
  /// points to the root of a new `Message`.
  public func copy() throws(PointerError) -> Self {
    .init(try struct$.copy())
  }
}

extension StructPointer {
  /// Performs a copy of the struct and the data it points to, returning a new `StructPointer`
  /// that points to the root of a new `Message`.
  public func copy() throws(PointerError) -> StructPointer {
    // +1 for the root pointer.
    let messageWords = try computeContentWordSize().add(1, orThrow: PointerError.sizeOverflow)
    let message = Message(withInitialWordCapacity: messageWords)
    let copy = message.rootPointer.initStruct(size: size)

    try copy.copy(from: self)

    assert(message.segmentCount == 1)
    assert(message.firstSegment.data.words == messageWords)

    return copy
  }

  package func copy(from struct_: StructPointer) throws(PointerError) {
    data.assertMutablePointer.copyMemory(
      from: struct_.data.pointer,
      byteCount: Int(struct_.size.dataBytes)
    )

    for i in 0..<struct_.size.pointers {
      guard let source = struct_.readAnyPointer(at: i) else {
        throw .pointerOutOfRange
      }
      let target = readAnyPointer(at: i)!

      try target.copy(from: source)
    }
  }

  /// Computes the size of the struct's content (excluding the pointer to it) in words, assuming a
  /// single segment (no far pointers).
  fileprivate func computeContentWordSize() throws(PointerError) -> UInt32 {
    var words = size.dataWords

    for i in 0..<size.pointers {
      // Each pointer's size includes the pointer itself, i.e. its slot in the pointer section.
      let pointerWords = try readAnyPointer(at: i)?.computeWordSize() ?? 1

      words = try words.add(pointerWords, orThrow: PointerError.sizeOverflow)
    }

    return words
  }
}
