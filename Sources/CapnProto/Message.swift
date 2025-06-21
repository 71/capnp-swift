import Foundation

/// A Cap'n Proto message encoded as one or more segments.
public struct Message: Freezable {
  /// The underlying data of the message.
  internal var data: Data = .init()

  /// Segments which make up the message. Cannot be empty.
  internal var segments: [Segment.Data] { data.segments }

  /// Whether the message is read-only, in which case all mutations will fail. `FrozenMessage`s
  /// and default structs are read-only.
  public var isReadOnly: Bool { data.readOnly }

  /// The number of segments in the message. Cannot be 0.
  public var segmentCount: UInt32 { UInt32(segments.count) }

  /// The first segment in the message.
  public var firstSegment: Segment { .init(segments.first!, in: self) }
  /// The last segment in the message.
  public var lastSegment: Segment { .init(segments.last!, in: self) }

  /// The root pointer, i.e. the first pointer in the first segment of the message.
  public var rootPointer: AnyPointer { .init(unsafePointer: .init(startOf: 0, in: self)) }

  /// Returns the segment at the given index.
  public func segment(at index: UInt32) -> Segment { .init(segments[Int(index)], in: self) }

  /// Constructs a new message with an initial segment with the given capacity.
  public init(withInitialWordCapacity capacity: UInt32 = 256) {
    // Ensure that the initial capacity is at least 1 word. We consider that the first word is
    // always used for the root pointer.
    add(segment: .init(wordCapacity: max(capacity, 1), initialWords: 1))
  }

  /// Constructs a new message with `capacity` segments reserved, but none yet assigned.
  ///
  /// It is invalid for a message to have no segments, so the caller should immediately add a
  /// segment following this call.
  internal init(unsafeSegmentCapacity capacity: Int) {
    assert(capacity > 0)

    data.segments.reserveCapacity(capacity)
  }

  /// Constructs a new read-only message constructed from a frozen copy of the given data.
  private init(freezingCopyOf data: Data) {
    self.data = data.copyFrozen()
  }

  /// Constructs a message with a single segment containing the given words. Returns `nil` if
  /// `segmentWords` is empty.
  public init?(segmentWords: [Word]) {
    guard !segmentWords.isEmpty else {
      return nil
    }

    let rawPointer = segmentWords.withUnsafeBytes { $0.baseAddress! }

    data.segments = [
      .init(
        words: UInt32(segmentWords.count),
        wordCapacity: UInt32(segmentWords.count),
        rawPointer: rawPointer,
        dealloc: { _ in _ = segmentWords }
      )
    ]
  }

  /// Returns a pointer to the root of the message, expecting it to be a struct `T`.
  public func root<T: Struct>(of type: T.Type = T.self) throws(PointerError) -> T {
    if let pointer = try rootPointer.resolve()?.expectStruct() {
      .init(pointer)
    } else {
      .init(.init())
    }
  }

  /// Initializes the root of the message with a struct of the given `size`.
  public func initRoot(size: StructSize) -> StructPointer {
    rootPointer.initStruct(size: size)
  }

  /// Initializes the root of the message with a struct of the given type `T`.
  public func initRoot<T: Struct>(of type: T.Type = T.self) -> T {
    .init(initRoot(size: T.size))
  }

  public mutating func freeze() -> Frozen<Message> {
    if isKnownUniquelyReferenced(&data) || data.readOnly {
      data.readOnly = true
      return .init(unsafeFrozen: self)
    }
    return .init(unsafeFrozen: .init(freezingCopyOf: data))
  }

  /// Allocates a number of contiguous words in the message, then returns a pointer which points
  /// to the first word of the allocated space.
  internal func allocate(words: UInt32) -> UnsafeMessagePointer {
    assert(!isReadOnly)

    // If the last segment has enough space, use it.
    if let pointer = tryAllocate(words: words, in: UInt32(segments.count - 1)) {
      return pointer
    }

    // Otherwise, create a new segment with (at least) the requested capacity.
    add(minWordCapacity: words, initialWords: words)

    return .init(segment: segmentCount - 1, in: self, offsetBytes: 0)
  }

  /// Attempts to allocate `words` words in the segment, returning a pointer to the first word of
  /// the allocated space if successful, or `nil` if the segment does not have enough space.
  internal func tryAllocate(words: UInt32, in segment: UInt32) -> UnsafeMessagePointer? {
    assert(!isReadOnly)

    let segmentData = data.segments[Int(segment)]
    let prevWords = segmentData.words
    let (newWords, overflow) = prevWords.addingReportingOverflow(words)

    guard !overflow, newWords <= segmentData.wordCapacity,
      let prevWordsInt = Int(exactly: prevWords)
    else { return nil }

    let (prevBytes, mulOverflow) = prevWordsInt.multipliedReportingOverflow(by: 8)

    guard !mulOverflow else { return nil }

    data.segments[Int(segment)].words = newWords

    return .init(segment: segment, in: self, offsetBytes: prevBytes)
  }

  /// Adds a segment with the given word capacity and initial words.
  private func add(minWordCapacity: UInt32, initialWords: UInt32) {
    add(
      segment: .init(
        wordCapacity: max(
          segments.last!.wordCapacity * 2,
          minWordCapacity.nextPowerOfTwo,
          512
        ),
        initialWords: initialWords
      )
    )
  }

  /// Adds a segment to the message using CoW semantics.
  fileprivate func add(segment: Segment.Data) {
    data.segments.append(segment)
  }

  /// The actual data of the `Message`. We use an indirection here to allow copy-on-write semantics.
  internal final class Data {
    var segments: [Segment.Data] = []
    var readOnly: Bool = false

    deinit {
      for segment in segments {
        segment.dealloc(segment.rawPointer)
      }
    }

    /// Returns a shallow copy of the data.
    func shallowCopy() -> Data {
      let copy = Data()
      copy.segments = segments
      return copy
    }

    /// Returns a copy of the data which is frozen and safe to share across threads.
    func copyFrozen() -> Data {
      let copy = Data()
      copy.segments = segments.map { $0.copy() }
      copy.readOnly = true
      return copy
    }
  }
}

/// A segment in a `Message`.
public struct Segment {
  /// The actual data of the `Segment`. We use an indirection here to allow copy-on-write semantics.
  internal struct Data {
    /// The size of the segment in words. Mutable (which would make `Data` non-sendable), but
    /// only mutated when we have a unique reference to the segment, which makes it safe.
    var words: UInt32
    /// The capacity of the segment in words.
    let wordCapacity: UInt32
    /// The underlying pointer.
    let rawPointer: UnsafeRawPointer
    /// The mode of the segment.
    let dealloc: (UnsafeRawPointer) -> Void

    /// The underlying buffer.
    var rawBuffer: UnsafeRawBufferPointer {
      UnsafeRawBufferPointer(start: rawPointer, count: Int(words) * MemoryLayout<Word>.size)
    }

    init(
      words: UInt32,
      wordCapacity: UInt32,
      rawPointer: UnsafeRawPointer,
      dealloc: @escaping (UnsafeRawPointer) -> Void
    ) {
      self.words = words
      self.wordCapacity = wordCapacity
      self.rawPointer = rawPointer
      self.dealloc = dealloc
    }

    init(wordCapacity: UInt32, initialWords: UInt32 = 0) {
      let rawPointer = UnsafeMutableRawPointer.allocate(
        byteCount: Int(wordCapacity) * 8,
        alignment: 8
      )
      memset(rawPointer, 0, Int(wordCapacity) * 8)

      self.init(
        words: initialWords,
        wordCapacity: wordCapacity,
        rawPointer: rawPointer,
        dealloc: { $0.deallocate() }
      )
    }

    func copy() -> Data {
      let copy = Data(wordCapacity: wordCapacity, initialWords: words)

      UnsafeMutableRawPointer(mutating: copy.rawPointer).copyMemory(
        from: rawPointer,
        byteCount: Int(wordCapacity) * 8
      )

      return copy
    }
  }

  /// The message which owns this segment.
  private(set) public var message: Message
  /// The underlying data.
  internal var data: Data

  fileprivate init(_ data: Data, in message: Message) {
    self.message = message
    self.data = data
  }

  public var buffer: UnsafeBufferPointer<Word> {
    .init(start: data.rawPointer.bindMemory(to: Word.self, capacity: 1), count: Int(data.words))
  }
}
