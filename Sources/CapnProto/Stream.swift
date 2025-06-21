import Foundation

// -------------------------------------------------------------------------------------------------
// MARK: MessageStreamError

/// Error encountered while decoding a `Message` over a stream.
public enum MessageStreamError: Error {
  case notEnoughData
  case indexOutOfBounds
  case integerOverflow
}

extension MessageStreamError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .notEnoughData:
      return "Not enough data"
    case .indexOutOfBounds:
      return "Index out of bounds"
    case .integerOverflow:
      return "Size integer overflow"
    }
  }
}

// -------------------------------------------------------------------------------------------------
// MARK: Message.fromStream()

extension Message {
  /// Returns a new `Message` parsed from its stream framing.
  public static func fromStream(data: some ContiguousBytes) throws(MessageStreamError) -> Message {
    do {
      return try data.withUnsafeBytes { bytes in
        try self.fromStream(copyingFrom: bytes.bindMemory(to: Word.self))
      }
    } catch let e as MessageStreamError {
      throw e
    } catch {
      fatalError()
    }
  }

  /// Returns a new `Message` parsed from its stream framing. Segments will be copied from the
  /// provided byte buffer and owned by the message.
  public static func fromStream(copyingFrom bytes: UnsafeBufferPointer<Word>)
    throws(MessageStreamError)
    -> Message
  {
    try .fromStream(bytes, borrowBytes: false)
  }

  /// Returns a new `Message` parsed from its stream framing. Segments will be borrowed from the
  /// provided byte buffer and must be kept alive for the lifetime of the message.
  public static func fromStream(unsafeBorrowingFrom bytes: UnsafeBufferPointer<Word>)
    throws(MessageStreamError) -> Message
  {
    try .fromStream(bytes, borrowBytes: true)
  }

  /// Wrapper around `fromStream(_:borrowBytes:)` which accepts a `UnsafeBufferPointer<Word>`.
  private static func fromStream(_ bytes: UnsafeBufferPointer<Word>, borrowBytes: Bool)
    throws(MessageStreamError) -> Message
  {
    try .fromStream(UnsafeRawBufferPointer(bytes), borrowBytes: borrowBytes)
  }

  /// Implementation of `fromStream(copyingFrom:)` and `fromStream(unsafeBorrowingFrom:)`.
  private static func fromStream(_ bytes: UnsafeRawBufferPointer, borrowBytes: Bool)
    throws(MessageStreamError) -> Message
  {
    // https://capnproto.org/encoding.html#serialization-over-a-stream
    guard bytes.count >= 8 else {
      throw .notEnoughData
    }

    // (4 bytes) The number of segments, minus one (since there is always at least one segment).
    let rawSegmentCount = bytes.loadLe(as: UInt32.self)
    guard rawSegmentCount != .max, let segmentCount = Int(exactly: rawSegmentCount + 1) else {
      throw .indexOutOfBounds
    }
    let paddingBytes = paddingBytesNeeded(forSegmentCount: segmentCount)
    let dataOffset = 4 + segmentCount * 4 + Int(paddingBytes)

    guard dataOffset <= bytes.count else {
      throw .notEnoughData
    }

    let requiredDataBytes = (0..<segmentCount).reduce(0) { sum, i in
      bytes.loadLe(fromByteOffset: 4 + i * 4, as: UInt32.self)
    }

    guard dataOffset + Int(requiredDataBytes) <= bytes.count else {
      throw .notEnoughData
    }

    let message = Message(unsafeSegmentCapacity: segmentCount)
    var dataPointer = bytes.baseAddress!.advanced(by: dataOffset)

    for i in 0..<segmentCount {
      // (N * 4 bytes) The size of each segment, in words.
      let segmentWords = bytes.loadLe(fromByteOffset: 4 + i * 4, as: UInt32.self)
      let segmentBytes = Int(segmentWords) * MemoryLayout<Word>.size

      if borrowBytes {
        message.data.segments.append(
          Segment.Data(
            words: segmentWords,
            wordCapacity: segmentWords,
            rawPointer: dataPointer,
            dealloc: { _ in }
          )
        )
      } else {
        let data = Segment.Data(wordCapacity: segmentWords, initialWords: segmentWords)

        UnsafeMutableRawPointer(mutating: data.rawPointer).copyMemory(
          from: dataPointer,
          byteCount: segmentBytes
        )

        message.data.segments.append(data)
      }

      dataPointer = dataPointer.advanced(by: segmentBytes)
    }

    return message
  }

  /// Returns a new `Message` parsed from a stream of byte chunks.
  @available(macOS 15, *)
  public func fromStream(_ chunks: some AsyncSequence<ArraySlice<UInt8>, any Error>)
    -> some AsyncSequence<
      Message, any Error
    >
  {
    AsyncDecoderSequence(source: chunks)
  }
}

// -------------------------------------------------------------------------------------------------
// MARK: Message.serialize()

extension Message {
  /// Returns the size of the message in bytes when serialized with `serialize()`.
  public func serializedSize() -> Int {
    // https://capnproto.org/encoding.html#serialization-over-a-stream

    // (4 bytes) The number of segments, minus one.
    let segmentCount = 4

    // (N * 4 bytes) The size of each segment, in words.
    let segmentSizes = segments.count * 4

    // (0 or 4 bytes) Padding up to the next word boundary.
    let padding = Int(paddingBytesNeeded(forSegmentCount: segments.count))

    // Segment data.
    let segmentDataSize = segments.reduce(0) { $0 + Int($1.words) * MemoryLayout<Word>.size }

    return segmentCount + segmentSizes + padding + segmentDataSize
  }

  /// Serializes the message into a `Data` object.
  public func serialize() -> Foundation.Data {
    // https://capnproto.org/encoding.html#serialization-over-a-stream

    var data = Foundation.Data(count: self.serializedSize())

    self.serialize(unsafeTo: &data)

    return data
  }

  /// Serializes the message into a `Data` buffer assumed to be large enough to store
  /// `serializedSize()` bytes.
  public func serialize(unsafeTo data: inout Foundation.Data) {
    data.withUnsafeMutableBytes { bytes in
      self.serialize(unsafeTo: bytes)
    }
  }

  /// Serializes the message into a mutable byte buffer. The buffer must be aligned to 8 bytes,
  /// and large enough to store `serializedSize()` bytes.
  public func serialize(unsafeTo bytes: UnsafeMutableRawBufferPointer) {
    // (4 bytes) The number of segments, minus one.
    bytes.storeBytes(of: UInt32(segments.count - 1), as: UInt32.self)

    // (N * 4 bytes) The size of each segment, in words.
    var offset = 4

    for segment in segments {
      let segmentWords = segment.words.littleEndian
      bytes.storeBytes(of: segmentWords, toByteOffset: offset, as: UInt32.self)
      offset += 4
    }

    // (0 or 4 bytes) Padding up to the next word boundary.
    if offset % 8 != 0 {
      bytes.storeBytes(of: 0, toByteOffset: offset, as: UInt32.self)
      offset += 4
    }

    // Segment data.
    var bytes = bytes.advanced(by: offset)

    for segment in segments {
      let segmentBytes = segment.rawBuffer
      segmentBytes.copyBytes(to: bytes)
      bytes.advance(by: segmentBytes.count)
    }
  }
}

// -------------------------------------------------------------------------------------------------
// MARK: AsyncDecoderSequence

/// An `AsyncSequence` which transforms an `AsyncSequence` of byte chunks into a sequence of
/// `Message`s.
@available(macOS 15, *)
private struct AsyncDecoderSequence<From: AsyncSequence>: AsyncSequence
where From.Element == ArraySlice<UInt8> {
  typealias Element = Message

  class Iterator: AsyncIteratorProtocol {
    typealias Element = Message

    var source: From.AsyncIterator
    var decoder: MessageStreamDecoder = .init()
    var pendingData: ArraySlice<UInt8> = .init()

    init(source: From.AsyncIterator) {
      self.source = source
    }

    func next() async throws -> Message? {
      // Process pending data.
      if !pendingData.isEmpty, let result = try decoder.push(pendingData) {
        pendingData = pendingData[result.readBytes...]

        return result.message
      }

      // Read more data from the source and parse it.
      while let data = try await source.next() {
        if let result = try decoder.push(data) {
          pendingData = data[result.readBytes...]

          return result.message
        }
      }

      if decoder.hasIncompleteMessage {
        // We have a partial message that we could not fully decode.
        throw MessageStreamError.notEnoughData
      }

      return nil
    }
  }

  let source: From

  init(source: From) {
    self.source = source
  }

  func makeAsyncIterator() -> Iterator {
    .init(source: source.makeAsyncIterator())
  }
}

// -------------------------------------------------------------------------------------------------
// MARK: MessageStreamDecoder

/// A decoder for a stream of Cap'n Proto messages.
public struct MessageStreamDecoder: ~Copyable {
  /// Result of pushing data into the decoder.
  public struct Result {
    /// The fully decoded message.
    public let message: Message
    /// The number of bytes read from the given buffer in order to produce `message`.
    public let readBytes: Int
  }

  /// Whether segment bytes should be borrowed rather than copied (if possible).
  private var borrowBytes = false

  private var state: State = .readSegmentCount(count: 0, byteIndex: 0)
  private var pendingSegments: [PendingSegment] = []

  public init() {}

  deinit {
    for segment in pendingSegments where segment.ownsData {
      segment.pointer?.deallocate()
    }
  }

  public var hasIncompleteMessage: Bool {
    switch state {
    case .readSegmentCount(count: 0, byteIndex: 0):
      return false
    default:
      return true
    }
  }

  /// Pushes a byte slice into the decoder. If a complete message is available, it is returned
  /// alongside the number of bytes read from `bytes`. If that number is lower than `bytes.count`,
  /// then more messages can be parsed by calling `push` again with the remaining bytes.
  public mutating func push(_ bytes: [UInt8]) throws(MessageStreamError) -> Result? {
    try self.push(bytes[...])
  }

  /// Overload of `push(data:)` which accepts a byte slice.
  public mutating func push(_ bytes: ArraySlice<UInt8>) throws(MessageStreamError) -> Result? {
    do {
      return try bytes.withUnsafeBytes { try self.push($0) }
    } catch let error as MessageStreamError {
      throw error
    } catch {
      fatalError()
    }
  }

  /// Overload of `push(data:)` which accepts some "data".
  public mutating func push(_ data: Data) throws(MessageStreamError) -> Result? {
    let data: some ContiguousBytes = data

    return try self.push(data)
  }

  /// Overload of `push(data:)` which accepts some "data".
  public mutating func push(_ data: some DataProtocol) throws(MessageStreamError) -> Result? {
    var readBytes = 0

    for region in data.regions {
      let region: some ContiguousBytes = region

      if let result = try self.push(region) {
        readBytes += result.readBytes

        return Result(message: result.message, readBytes: readBytes + result.readBytes)
      }

      readBytes += region.withUnsafeBytes { $0.count }
    }

    return nil
  }

  /// Overload of `push(data:)` which accepts contiguous bytes.
  public mutating func push(_ bytes: some ContiguousBytes) throws(MessageStreamError) -> Result? {
    do {
      return try bytes.withUnsafeBytes { try self.push($0) }
    } catch let error as MessageStreamError {
      throw error
    } catch {
      fatalError()
    }
  }

  /// Overload of `push(data:)` which accepts a raw buffer pointer.
  public mutating func push(_ bytes: UnsafeRawBufferPointer) throws(MessageStreamError) -> Result? {
    try self.push(bytes, borrowBytes: false)
  }

  /// Overload of `push(data:)` which accepts a raw buffer pointer and avoids copies whenever possible.
  public mutating func push(unsafeBorrowingFrom bytes: UnsafeRawBufferPointer)
    throws(MessageStreamError) -> Result?
  {
    try self.push(bytes, borrowBytes: true)
  }
}

// -------------------------------------------------------------------------------------------------
// MARK: Decoding logic

private enum State {
  case readSegmentCount(count: UInt32, byteIndex: UInt8)
  case readSegmentSize(segmentIndex: UInt32, words: UInt32, byteIndex: UInt8)
  case readSegmentData(segmentIndex: UInt32, paddingLeft: UInt8)
}

extension MessageStreamDecoder {
  /// Implementation of `push(bytes:)` which sets `borrowBytes` as specified before running.
  private mutating func push(_ bytes: UnsafeRawBufferPointer, borrowBytes: Bool = false)
    throws(MessageStreamError) -> Result?
  {
    self.borrowBytes = borrowBytes

    let countBefore = bytes.count
    var bytes = bytes
    var message: Message?

    while bytes.count > 0 {
      switch state {
      case .readSegmentCount(count: 0, byteIndex: 0) where bytes.count >= 4:
        // We can read the whole segment count in one go.
        //
        // (4 bytes) The number of segments, minus one (since there is always at least one segment).
        let count = bytes.loadLe(as: UInt32.self)
        bytes.advance(by: 4)

        message = try readSegmentSizes(&bytes, segmentCount: count + 1)

      case .readSegmentCount(let count, let byteIndex):
        message = try readSegmentCountSlow(&bytes, count: count, byteIndex: byteIndex)

      case .readSegmentSize(let segmentIndex, let words, let byteIndex):
        message = try readSegmentSizeSlow(
          &bytes,
          segmentIndex: segmentIndex,
          words: words,
          byteIndex: byteIndex
        )

      case .readSegmentData(let segmentIndex, let paddingLeft):
        message = readSegmentData(
          &bytes,
          segmentIndex: segmentIndex,
          paddingLeft: paddingLeft
        )
      }

      if let message {
        return Result(message: message, readBytes: countBefore - bytes.count)
      }
    }

    return nil
  }

  private mutating func readSegmentCountSlow(
    _ bytes: inout UnsafeRawBufferPointer,
    count: UInt32,
    byteIndex: UInt8
  ) throws(MessageStreamError) -> Message? {
    precondition(!bytes.isEmpty)

    var count = count
    var byteIndex = byteIndex

    while true {
      count |= UInt32(bytes.load(as: UInt8.self)) << (8 * byteIndex)
      byteIndex += 1
      bytes.advance(by: 1)

      if byteIndex == 4 {
        // (4 bytes) The number of segments, minus one (since there is always at least one segment).
        return try readSegmentSizes(&bytes, segmentCount: count + 1)
      }
      if bytes.isEmpty {
        state = .readSegmentCount(count: count, byteIndex: byteIndex)
        return nil
      }
    }
  }

  private mutating func readSegmentSizes(
    _ bytes: inout UnsafeRawBufferPointer,
    segmentCount: UInt32
  ) throws(MessageStreamError) -> Message? {
    precondition(segmentCount > 0)

    pendingSegments.reserveCapacity(Int(segmentCount))

    // Add segments whose size we could not read immediately.
    while pendingSegments.count < segmentCount {
      pendingSegments.append(.unallocated(byteLength: 0))
    }

    return try readSegmentSizes(&bytes, segmentCount: segmentCount, from: 0)
  }

  private mutating func readSegmentSizes(
    _ bytes: inout UnsafeRawBufferPointer,
    segmentCount: UInt32,
    from: UInt32
  ) throws(MessageStreamError) -> Message? {
    // Add segments whose size we can read immediately.
    //
    // (N * 4 bytes) The size of each segment, in words.
    var i: UInt32 = from

    while bytes.count >= 4 {
      let segmentWords = bytes.loadLe(as: UInt32.self)
      let segmentBytes = try Int(
        fromUInt32: segmentWords,
        multipliedBy: 8,
        orThrow: MessageStreamError.indexOutOfBounds
      )

      pendingSegments[Int(i)] = .unallocated(byteLength: segmentBytes)

      bytes.advance(by: 4)
      i += 1

      if i == segmentCount {
        // We have read all segment sizes. Move on to their data.
        return readSegmentData(
          &bytes,
          segmentIndex: 0,
          paddingLeft: paddingBytesNeeded(forSegmentCount: segmentCount)
        )
      }
    }

    // Update state.
    var byteIndex: UInt8 = 0
    var words: UInt32 = 0

    while bytes.count > 0 {
      words |= UInt32(bytes.load(as: UInt8.self)) << (8 * byteIndex)
      byteIndex += 1
      bytes.advance(by: 1)
    }

    state = .readSegmentSize(segmentIndex: i, words: words, byteIndex: byteIndex)
    return nil
  }

  private mutating func readSegmentSizeSlow(
    _ bytes: inout UnsafeRawBufferPointer,
    segmentIndex: UInt32,
    words: UInt32,
    byteIndex: UInt8
  ) throws(MessageStreamError) -> Message? {
    precondition(!bytes.isEmpty)
    precondition(byteIndex < 4)

    var byteIndex = byteIndex
    var words = words

    while true {
      words |= UInt32(bytes.load(as: UInt8.self)) << (8 * byteIndex)
      byteIndex += 1
      bytes.advance(by: 1)

      if byteIndex == 4 {
        // We have read the whole segment size.
        break
      }

      if bytes.isEmpty {
        // Not enough bytes to read the whole segment size.
        state = .readSegmentSize(
          segmentIndex: segmentIndex,
          words: words,
          byteIndex: byteIndex
        )
        return nil
      }
    }

    let segmentBytes = Int(words) * MemoryLayout<Word>.size

    pendingSegments[Int(segmentIndex)] = .unallocated(byteLength: segmentBytes)

    if segmentIndex + 1 == pendingSegments.count {
      // We have read all segment sizes. Move on to their data.
      return readSegmentData(
        &bytes,
        segmentIndex: 0,
        paddingLeft: paddingBytesNeeded(forSegmentCount: pendingSegments.count)
      )
    } else {
      // Move on to the next segment size.
      return try readSegmentSizes(
        &bytes,
        segmentCount: UInt32(pendingSegments.count),
        from: segmentIndex + 1
      )
    }
  }

  private mutating func readSegmentData(
    _ bytes: inout UnsafeRawBufferPointer,
    segmentIndex: UInt32,
    paddingLeft: UInt8
  ) -> Message? {
    if paddingLeft > 0 {
      // We need to skip some padding bytes.
      if bytes.count < paddingLeft {
        // We can't skip the whole padding.
        bytes.advance(by: bytes.count)
        state = .readSegmentData(
          segmentIndex: segmentIndex,
          paddingLeft: paddingLeft - UInt8(bytes.count)
        )
        return nil
      }

      // Skip the whole padding and keep going.
      bytes.advance(by: Int(paddingLeft))
    }

    var segmentIndex = Int(segmentIndex)

    precondition(segmentIndex < pendingSegments.count)

    while true {
      let segment = pendingSegments[segmentIndex]
      let segmentNeedsBytes = segment.byteLength - segment.byteOffset

      if segmentNeedsBytes > bytes.count {
        // Not enough bytes to read the whole segment. Copy what we can and stop.
        let segmentPointer = pendingSegments[segmentIndex].pointerOrAllocate()
        let segmentDataLeft = UnsafeMutableRawBufferPointer(
          start: segmentPointer.advanced(by: Int(segment.byteOffset)),
          count: Int(segmentNeedsBytes)
        )

        pendingSegments[segmentIndex].byteOffset += bytes.count
        bytes.copyBytes(to: segmentDataLeft)
        bytes.advance(by: bytes.count)
        state = .readSegmentData(segmentIndex: UInt32(segmentIndex), paddingLeft: 0)
        return nil
      }

      // We can fill the whole segment.
      if borrowBytes && segment.pointer == nil {
        // Borrow the bytes without copying.
        pendingSegments[segmentIndex] = .borrowed(
          pointer: bytes.baseAddress!,
          byteLength: segment.byteLength
        )
      } else {
        // Copy the bytes into the segment.
        let segmentPointer = pendingSegments[segmentIndex].pointerOrAllocate()
        let segmentDataLeft = UnsafeMutableRawBufferPointer(
          start: segmentPointer.advanced(by: Int(segment.byteOffset)),
          count: Int(segmentNeedsBytes)
        )
        pendingSegments[segmentIndex].byteOffset = segment.byteLength
        bytes.copyBytes(to: segmentDataLeft)
      }
      bytes.advance(by: Int(segmentNeedsBytes))

      segmentIndex += 1

      if segmentIndex == pendingSegments.count {
        break
      }
    }

    self.state = .readSegmentCount(count: 0, byteIndex: 0)

    // We have read all segments. Create a new message.
    let message = Message(unsafeSegmentCapacity: pendingSegments.count)

    for segment in pendingSegments {
      assert(segment.byteOffset == segment.byteLength)
      assert(segment.byteLength % 8 == 0)

      let words = UInt32(segment.byteLength / 8)

      message.data.segments.append(
        .init(
          words: words,
          wordCapacity: words,
          rawPointer: segment.pointer!,
          dealloc: segment.ownsData ? { $0.deallocate() } : { _ in }
        )
      )
    }

    pendingSegments.removeAll(keepingCapacity: true)

    return message
  }
}

// -------------------------------------------------------------------------------------------------
// MARK: Decoding helpers

private struct PendingSegment {
  var pointer: UnsafeMutableRawPointer?
  let byteLength: Int
  var byteOffset: Int
  var ownsData: Bool

  static func unallocated(byteLength: Int) -> PendingSegment {
    .init(pointer: nil, byteLength: byteLength, byteOffset: 0, ownsData: false)
  }

  static func borrowed(pointer: UnsafeRawPointer, byteLength: Int) -> PendingSegment {
    .init(
      pointer: .init(mutating: pointer),
      byteLength: byteLength,
      byteOffset: byteLength,
      ownsData: false
    )
  }

  mutating func pointerOrAllocate() -> UnsafeMutableRawPointer {
    if let pointer = pointer {
      return pointer
    }

    // Allocate a new buffer for the segment data.
    let newPointer = UnsafeMutableRawPointer.allocate(
      byteCount: byteLength,
      alignment: MemoryLayout<Word>.alignment
    )
    ownsData = true
    pointer = newPointer

    return newPointer
  }
}

private func paddingBytesNeeded(forSegmentCount segmentCount: UInt32) -> UInt8 {
  // Segment count: 4 bytes.
  // Segment sizes: 4 bytes each.
  //
  // One segment : 4 bytes (segment count) + 4 bytes (segment size) = 8  bytes.
  // Two segments: 4 bytes (segment count) + 8 bytes (segment size) = 12 bytes.
  //
  // So we need padding for even segment counts.
  if segmentCount % 2 == 0 {
    4
  } else {
    0
  }
}

private func paddingBytesNeeded(forSegmentCount segmentCount: Int) -> UInt8 {
  paddingBytesNeeded(forSegmentCount: UInt32(segmentCount))
}
