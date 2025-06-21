/// A pointer to a value stored in a `Message` segment.
///
/// A pointer is generally unsafe to use as it does not perform any bounds checking or validation,
/// which is assumed to have been done by the caller. It is used by other types in this library to
/// read and write values in a `Message`.
///
/// A pointer points to a _byte_ in a segment, not to a _word_. This is required to support reading
/// lists of elements smaller than a word.
public struct UnsafeMessagePointer: Freezable {
  /// The maximum value which may be given to `traversalLimit` when creating a pointer.
  public static let maxTraversalLimit: UInt16 = (1 << 15) - 1
  /// The default value for `traversalLimit` when creating a pointer.
  public static let defaultTraversalLimit: UInt16 = 64

  /// Returns a pointer to an empty message.
  public static let null: Frozen<UnsafeMessagePointer> = {
    // Create a message with a root pointer and nothing else.
    let message = Message(segmentWords: [0])!
    var pointer = message.rootPointer.unsafePointer
    return pointer.freeze()
  }()

  /// Pointer to the value. Safe to keep as we store a reference to its owning `Message`.
  public let pointer: UnsafeRawPointer

  /// Message which owns the data.
  private(set) public var message: Message

  /// Bits which store the mutable and traversal limit flags.
  private let mutableAndTraversalLimit: UInt16

  /// Index of the segment in `message.segments`.
  public let segmentIndex: UInt32

  /// Whether the pointer is mutable.
  internal var isMutable: Bool { (mutableAndTraversalLimit & 1) == 1 }

  /// Whether the pointer is read-only, in which case all mutations will fail, as if operating on
  /// zero-sized structs.
  public var isReadOnly: Bool { !isMutable }

  /// The maximum number of pointers that can be dereferenced from this pointer.
  public var traversalLimit: UInt16 { mutableAndTraversalLimit >> 1 }

  /// Offset from the start of the segment to the pointee in bytes.
  public var byteOffset: Int {
    message.segments[Int(segmentIndex)].rawPointer.distance(to: pointer)
  }
  /// Offset from the start of the segment to the pointee in words.
  public var wordOffset: UInt32 { UInt32(byteOffset / 8) }

  /// Segment which stores the data.
  public var segment: Segment { message.segment(at: segmentIndex) }

  /// Mutable pointer to the value. If the underlying segment is not mutable or referenced by
  /// other pointers, it will be copied and owned by this pointer.
  public var mutablePointer: UnsafeMutableRawPointer? {
    isMutable ? .init(mutating: pointer) : nil
  }

  /// Asserts `!isReadOnly` and returns a mutable pointer to the value.
  internal var assertMutablePointer: UnsafeMutableRawPointer {
    assert(!isReadOnly)

    return .init(mutating: pointer)
  }

  internal init(
    message: Message,
    segmentIndex: UInt32,
    pointer: UnsafeRawPointer,
    traversalLimit: UInt16 = defaultTraversalLimit,
    readOnly: Bool = false
  ) {
    assert(segmentIndex < message.segments.count)

    let readOnly = readOnly || message.isReadOnly

    self.message = message
    self.segmentIndex = segmentIndex
    self.pointer = pointer
    self.mutableAndTraversalLimit =
      ((traversalLimit & Self.maxTraversalLimit) << 1)
      | (readOnly ? 0 : 1)
  }

  /// Creates a pointer to the start of the first segment of the given message.
  public init(
    startOf message: Message,
    traversalLimit: UInt16 = defaultTraversalLimit,
    readOnly: Bool = false
  ) {
    self.init(
      message: message,
      segmentIndex: 0,
      pointer: message.segments.first!.rawPointer,
      traversalLimit: traversalLimit
    )
  }

  /// Creates a pointer to the start of the specified segment in the message.
  public init(
    startOf segment: UInt32,
    in message: Message,
    traversalLimit: UInt16 = defaultTraversalLimit,
    readOnly: Bool = false
  ) {
    precondition(segment < message.segments.count)

    self.init(
      message: message,
      segmentIndex: segment,
      pointer: message.segments[Int(segment)].rawPointer,
      traversalLimit: traversalLimit,
      readOnly: readOnly
    )
  }

  /// Creates a pointer to the specified segment, offset by the given number of bytes.
  public init(
    segment: UInt32,
    in message: Message,
    offsetBytes: Int,
    traversalLimit: UInt16 = defaultTraversalLimit,
    readOnly: Bool = false
  ) {
    precondition(segment < message.segments.count)
    precondition(offsetBytes <= message.segments[Int(segment)].rawBuffer.count)

    self.init(
      message: message,
      segmentIndex: segment,
      pointer: message.segments[Int(segment)].rawPointer.advanced(by: offsetBytes),
      traversalLimit: traversalLimit,
      readOnly: readOnly
    )
  }

  /// Creates a pointer to the specified segment, offset by the given number of words.
  public init(
    segment: UInt32,
    in message: Message,
    offsetWords: UInt32,
    traversalLimit: UInt16 = defaultTraversalLimit,
    readOnly: Bool = false
  ) throws(PointerError) {
    self.init(
      segment: segment,
      in: message,
      offsetBytes: try offsetWords.wordsToBytes(orThrow: PointerError.pointerOutOfRange),
      traversalLimit: traversalLimit,
      readOnly: readOnly
    )
  }

  /// Returns a (shallow) copy of this pointer, but with the `readOnly` flag set to `true`.
  public func asReadOnly() -> UnsafeMessagePointer {
    .init(
      message: message,
      segmentIndex: segmentIndex,
      pointer: pointer,
      traversalLimit: traversalLimit,
      readOnly: true
    )
  }

  public mutating func freeze() -> Frozen<UnsafeMessagePointer> {
    .init(
      unsafeFrozen: .init(
        message: message.freeze().value,
        segmentIndex: segmentIndex,
        pointer: pointer,
        traversalLimit: traversalLimit,
        readOnly: true
      )
    )
  }

  /// Returns a pointer pointing to a value at a specified offset from this pointer in the same
  /// segment.
  internal func advanced(byBytes offset: Int) -> UnsafeMessagePointer {
    .init(
      message: message,
      segmentIndex: segmentIndex,
      pointer: pointer.advanced(by: offset),
      traversalLimit: traversalLimit,
      readOnly: isReadOnly
    )
  }

  /// Returns a pointer pointing to a value at a specified offset from this pointer in the same
  /// segment.
  internal func advanced(byWords offset: UInt32) throws(PointerError) -> UnsafeMessagePointer {
    self.advanced(byBytes: try offset.wordsToBytes(orThrow: PointerError.pointerOutOfRange))
  }
}

extension UnsafeMessagePointer {
  private static let emptyPointer: Frozen<UnsafeMessagePointer> = {
    var message = Message(segmentWords: [0])!
    let frozenMessage = message.freeze()

    return Frozen(
      unsafeFrozen: .init(
        message: frozenMessage.value,
        segmentIndex: 0,
        pointer: frozenMessage.value.segments[0].rawPointer.advanced(by: 8),
        traversalLimit: defaultTraversalLimit,
        readOnly: true
      )
    )
  }()

  /// Returns a pointer to the start of a message with the given words.
  public static func readOnly(words: [Word]) -> UnsafeMessagePointer {
    guard var message = Message(segmentWords: words) else { return emptyPointer.value }

    return .init(
      startOf: message.freeze().value,
      traversalLimit: defaultTraversalLimit,
      readOnly: true
    )
  }

  /// Returns a pointer to the start of a message with the given words.
  public static func readOnly(bytes: UnsafeRawBufferPointer) -> UnsafeMessagePointer {
    let wordsCount = bytes.count.divideRoundingUp(by: 8)
    let words = [Word](unsafeUninitializedCapacity: wordsCount) { (wordsBytes, count) in
      bytes.copyBytes(to: wordsBytes)
      count = wordsCount
    }
    return .readOnly(words: words)
  }
}
