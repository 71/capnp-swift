import CapnProto
import Foundation
import Testing

@Test
func traversalLimit() throws {
  let test = TestSelfReference()
  var current = test

  for i in 0..<UnsafeMessagePointer.defaultTraversalLimit + 1 {
    current.i = i
    current = current.initRef()!
  }

  current = test
  for i in 0..<UnsafeMessagePointer.defaultTraversalLimit {
    try #require(current.i == i)
    current = try current.ref()
  }

  #expect(throws: PointerError.traversalLimitExceeded) {
    try current.ref()
  }
}

@Test
func badData() throws {
  let message = Message(segmentWords: [.max])!

  #expect(throws: PointerError.self) {
    _ = try message.root(of: TestValues.self)
  }
}

// -------------------------------------------------------------------------------------------------
// MARK: Malformed and multi-segment messages

/// Encodes a struct pointer with the given raw offset (relative to the end of the pointer).
private func structPointer(offset: Int32, dataWords: UInt16, pointers: UInt16) -> Word {
  (Word(UInt32(bitPattern: offset) & 0x3FFF_FFFF) << 2)
    | (Word(dataWords) << 32)
    | (Word(pointers) << 48)
}

/// Encodes a list pointer with the given raw offset, element size and count (or word count, for
/// composite lists).
private func listPointer(offset: Int32, elementSize: UInt8, count: UInt32) -> Word {
  1 | (Word(UInt32(bitPattern: offset) & 0x3FFF_FFFF) << 2)
    | (Word(UInt32(elementSize) | (count << 3)) << 32)
}

/// Returns the bytes of `string` packed into little-endian words, zero-padded.
private func words(of string: String) -> [Word] {
  var bytes = Array(string.utf8)
  bytes += Array(repeating: 0, count: (8 - bytes.count % 8) % 8)

  return stride(from: 0, to: bytes.count, by: 8).map { i in
    bytes[i..<i + 8].reversed().reduce(0) { ($0 << 8) | Word($1) }
  }
}

@Test
func farPointerRoundTrip() throws {
  // The first segment only fits the root pointer and the struct, so `ints` goes into a second
  // segment, and `text` then lands at a non-zero offset of that second segment.
  let message = Message(withInitialWordCapacity: 1 + TestValues.size.sizeInWords)
  let root = message.initRoot(of: TestValues.self)
  root.enum = .b

  let ints = try #require(root.initInts(count: 2000))
  for i in 0..<ints.count {
    #expect(ints.write(UInt32(i), at: i))
  }
  _ = try #require(root.setText("far away"))

  try #require(message.segmentCount == 2)

  let decoded = try Message.fromStream(data: message.serialize())
  let decodedRoot = try decoded.root(of: TestValues.self)
  let decodedInts = try decodedRoot.ints()

  #expect(decodedRoot.enum == .b)
  #expect(try decodedRoot.text().toString() == "far away")
  #expect(decodedInts.count == 2000)
  #expect(decodedInts[1999] == 1999)
}

@Test
func pointerBeforeSegmentStart() throws {
  // Offset -2 from the end of the root pointer is one word before the segment; the 2-word
  // struct still ends inside the segment.
  let message = Message(segmentWords: [
    structPointer(offset: -2, dataWords: 2, pointers: 0), 0, 0, 0,
  ])!

  #expect(throws: PointerError.pointerOutOfRange) {
    _ = try message.rootPointer.resolve()
  }
}

@Test
func fromStreamTruncatedSegments() throws {
  // One segment of 4 words, but only one word of data.
  let oneSegment: [UInt8] = [0, 0, 0, 0, 4, 0, 0, 0] + Array(repeating: 0, count: 8)

  #expect(throws: MessageStreamError.notEnoughData) {
    _ = try Message.fromStream(data: oneSegment)
  }

  // Two segments; only the first one (1 word) is present, the second one claims 100 words.
  let twoSegments: [UInt8] =
    [1, 0, 0, 0, 1, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0] + Array(repeating: 0, count: 16)

  #expect(throws: MessageStreamError.notEnoughData) {
    _ = try Message.fromStream(data: twoSegments)
  }
}

@Test
func fromStreamTooManySegments() throws {
  let header: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF] + Array(repeating: 0, count: 12)

  #expect(throws: MessageStreamError.tooManySegments) {
    _ = try Message.fromStream(data: header)
  }

  // Fast path: the whole segment count is available at once.
  var decoder = MessageStreamDecoder()
  #expect(throws: MessageStreamError.tooManySegments) {
    _ = try decoder.push([0xFF, 0xFF, 0xFF, 0xFF])
  }

  // 512 segments are accepted (one word each, first segment holding a null root), 513 are not.
  #expect(try Message.fromStream(data: segmentHeader(count: 512)).segmentCount == 512)
  #expect(throws: MessageStreamError.tooManySegments) {
    _ = try Message.fromStream(data: segmentHeader(count: 513))
  }

  // Slow path: the segment count is split across pushes.
  var slowDecoder = MessageStreamDecoder()
  #expect(try slowDecoder.push([0x00, 0x10]) == nil)
  #expect(throws: MessageStreamError.tooManySegments) {
    _ = try slowDecoder.push([0x00, 0x00])
  }
}

@Test
func freezeSharedMessage() throws {
  let message = Message()
  let root = message.initRoot(of: TestValues.self)
  root.enum = .b

  // `message` and `root` still reference the message, so `freeze()` must copy it.
  var copy = root
  let frozen = copy.freeze()

  root.enum = .c

  #expect(frozen.value.enum == .b)
  #expect(root.enum == .c)
}

@Test
func nestedListElementSizeIsChecked() throws {
  // Root: list of 1 pointer, pointing to a list of 8 bytes.
  let message = Message(segmentWords: [
    listPointer(offset: 0, elementSize: 6, count: 1),
    listPointer(offset: 0, elementSize: 2, count: 8),
  ] + words(of: "abcdefgh"))!
  let rootList = try #require(try message.rootPointer.resolve()?.expectList())

  let wrongSize = try #require(List<List<UInt64>>(verifying: rootList))
  #expect(throws: PointerError.unexpectedPointerType) {
    _ = try wrongSize.read(at: 0)
  }

  let rightSize = try #require(List<List<UInt8>>(verifying: rootList))
  #expect(try rightSize.read(at: 0).count == 8)

  let texts = try #require(List<Text>(verifying: rootList))
  #expect(try texts.read(at: 0).toString() == "abcdefgh")

  // A list of `Text` whose element is a list of words must also be rejected.
  let wordMessage = Message(segmentWords: [
    listPointer(offset: 0, elementSize: 6, count: 1),
    listPointer(offset: 0, elementSize: 5, count: 1),
    0,
  ])!
  let wordRootList = try #require(try wordMessage.rootPointer.resolve()?.expectList())
  let wrongTexts = try #require(List<Text>(verifying: wordRootList))

  #expect(throws: PointerError.unexpectedPointerType) {
    _ = try wrongTexts.read(at: 0)
  }
}

@Test
func compositeListSizeOverflow() throws {
  // Tag word: 2^29 elements of 16 data words each, which overflows `UInt32`.
  let tagWord = structPointer(offset: 1 << 29, dataWords: 16, pointers: 0)
  let message = Message(segmentWords: [
    listPointer(offset: 0, elementSize: 7, count: 0),
    tagWord,
  ])!

  #expect(throws: PointerError.invalidCompositeList) {
    _ = try message.rootPointer.resolve()
  }
}

@Test
func textToStringUsesCount() throws {
  // Root: list of 8 bytes with no NUL terminator, followed by non-zero bytes.
  let message = Message(segmentWords: [
    listPointer(offset: 0, elementSize: 2, count: 8)
  ] + words(of: "abcdefghijklmno"))!
  let bytes = try #require(try message.rootPointer.resolve()?.expectList())
  let text = Text(try #require(List<UInt8>(verifying: bytes)))

  #expect(text.toString() == "abcdefgh")

  // Embedded NULs are kept, and only the trailing one is dropped.
  let nulMessage = Message(segmentWords: [
    listPointer(offset: 0, elementSize: 2, count: 6)
  ] + words(of: "ab\0cd\0"))!
  let nulBytes = try #require(try nulMessage.rootPointer.resolve()?.expectList())
  let nulText = Text(try #require(List<UInt8>(verifying: nulBytes)))

  #expect(nulText.toString() == "ab\0cd")
}

/// Encodes a far pointer to the given landing pad.
private func farPointer(segment: UInt32, offset: UInt32, doubleFar: Bool = false) -> Word {
  2 | (doubleFar ? 0b100 : 0) | (Word(offset) << 3) | (Word(segment) << 32)
}

/// Builds a message with the given segments by going through the stream framing.
private func message(segments: [[Word]]) throws -> Message {
  var words: [UInt32] = [UInt32(segments.count - 1)] + segments.map { UInt32($0.count) }
  if words.count % 2 != 0 {
    words.append(0)  // Padding.
  }

  var bytes = words.withUnsafeBytes { Array($0) }
  for segment in segments {
    bytes += segment.withUnsafeBytes { Array($0) }
  }

  return try Message.fromStream(data: bytes)
}

/// Returns a message with two segments, so that its framing includes 4 bytes of padding.
private func twoSegmentMessage() throws -> Message {
  let message = Message(withInitialWordCapacity: 1 + TestValues.size.sizeInWords)
  let root = message.initRoot(of: TestValues.self)
  root.enum = .c

  let ints = try #require(root.initInts(count: 2000))
  #expect(ints.write(42, at: 1999))

  try #require(message.segmentCount == 2)

  return message
}

@Test
func farPointerCycleHitsTraversalLimit() throws {
  // The root points to a struct whose only pointer is a far pointer back to that struct.
  let message = try message(segments: [
    [farPointer(segment: 1, offset: 0)],
    [structPointer(offset: 0, dataWords: 0, pointers: 1), farPointer(segment: 1, offset: 0)],
  ])

  var current = try #require(try message.rootPointer.resolve()?.expectStruct())
  var depth = 0

  #expect(throws: PointerError.traversalLimitExceeded) {
    while depth < 1000 {
      current = try #require(try current.readStructPointer(at: 0))
      depth += 1
    }
  }
  #expect(depth < Int(UnsafeMessagePointer.defaultTraversalLimit))

  #expect(throws: PointerError.traversalLimitExceeded) {
    _ = try message.rootPointer.copy()
  }
}

@Test
func readOnlyIsInherited() throws {
  let root = TestSelfReference()
  _ = try #require(root.initRef())

  let readOnlyRoot = root.asReadOnly()
  #expect(try readOnlyRoot.ref().struct$.data.isReadOnly)
  #expect(try !root.ref().struct$.data.isReadOnly)

  let message = Message()
  #expect(UnsafeMessagePointer(startOf: message, readOnly: true).isReadOnly)
}

@Test
func doubleFarPointer() throws {
  let message = try message(segments: [
    [farPointer(segment: 1, offset: 0, doubleFar: true)],
    [
      farPointer(segment: 2, offset: 0),
      structPointer(offset: 0, dataWords: 1, pointers: 0),
    ],
    [42],
  ])

  let root = try #require(try message.rootPointer.resolve()?.expectStruct())
  #expect(root.read(atByte: 0) as UInt64 == 42)

  // A landing pad whose bit 2 is set is not a far pointer.
  let badMessage = try CapnProtoTests.message(segments: [
    [farPointer(segment: 1, offset: 0, doubleFar: true)],
    [0b100, structPointer(offset: 0, dataWords: 1, pointers: 0)],
  ])
  #expect(throws: PointerError.invalidFarPointer) {
    _ = try badMessage.rootPointer.resolve()
  }
}

@Test
func capabilityPointer() throws {
  let message = Message(segmentWords: [3 | (5 << 32)])!
  let capability = try #require(try message.rootPointer.resolve()?.expectCapability())
  #expect(capability.capabilityIndex == 5)

  let badMessage = Message(segmentWords: [3 | (1 << 2) | (5 << 32)])!
  #expect(throws: PointerError.unknownPointerType) {
    _ = try badMessage.rootPointer.resolve()
  }
}

@Test
func copyStructAndLists() throws {
  // `enum` is `a`, so the first word of the struct is zero.
  let values = TestValues()
  _ = try #require(values.setText("hello"))
  let ints = try #require(values.initInts(count: 3))
  #expect(ints.write(7, at: 2))

  let valuesCopy = try values.copy()
  _ = values.setText("changed")

  #expect(valuesCopy.enum == .a)
  #expect(try valuesCopy.text().toString() == "hello")
  #expect(try Array(valuesCopy.ints()) == [0, 0, 7])
  #expect(try Array(valuesCopy.ints().copy()) == [0, 0, 7])

  // Composite list of structs with pointers.
  let addressBook = AddressBook()
  let people = try #require(addressBook.initPeople(count: 3))
  for (i, name) in ["Alice", "Bob", "Carol"].enumerated() {
    people[i].id = UInt32(i)
    _ = try #require(people[i].setName(Substring(name)))
    let phones = try #require(people[i].initPhones(count: 1))
    _ = try #require(phones[0].setNumber("555-000\(i)"))
  }

  let peopleCopy = try people.copy()
  #expect(peopleCopy.count == 3)
  for (i, name) in ["Alice", "Bob", "Carol"].enumerated() {
    #expect(peopleCopy[i].id == UInt32(i))
    #expect(try peopleCopy[i].name().toString() == name)
    #expect(try peopleCopy[i].phones()[0].number().toString() == "555-000\(i)")
  }

  let addressBookCopy = try addressBook.copy()
  #expect(try addressBookCopy.people()[2].name().toString() == "Carol")
}

@Test
func boolAccessorsStayInDataSection() throws {
  let struct$ = StructPointer(size: StructSize(safeDataBytes: 8, pointers: 1))
  // The child's pointer word has its data size (1 word) at bit 32, i.e. bit 96 of the parent.
  _ = try #require(struct$.initStructPointer(at: 0, size: .init(safeDataBytes: 8, pointers: 0)))

  #expect(!struct$.read(atBit: 96))
  #expect(!struct$.write(true, atBit: 96))
  #expect(try struct$.readStructPointer(at: 0)?.size.dataWords == 1)

  #expect(struct$.write(true, atBit: 63))
  #expect(struct$.read(atBit: 63))
}

@Test
func textIsNulTerminated() throws {
  // `List<Text>.write()`.
  let struct$ = StructPointer(size: StructSize(safeDataBytes: 0, pointers: 1))
  let texts: List<Text> = try #require(struct$.initList(at: 0, count: 1))
  #expect(texts.write("abcdefgh", at: 0))

  let text = try texts.read(at: 0)
  #expect(text.bytes.count == 9)
  #expect(text.bytes[8] == 0)
  #expect(text.toString() == "abcdefgh")

  // `Text.readOnly()`.
  let readOnly = Text.readOnly("abcdefgh")
  #expect(readOnly.bytes.count == 9)
  #expect(readOnly.bytes[8] == 0)
  #expect(readOnly.toString() == "abcdefgh")

  // Padding is zero-filled.
  let pointer = [UInt8]([1, 2, 3]).withUnsafeBytes { UnsafeMessagePointer.readOnly(bytes: $0) }
  #expect(pointer.message.firstSegment.buffer[0] == 0x03_02_01)
}

@Test
func readStructListWrittenWithOtherSchema() throws {
  // A list of structs larger than `TestSelfReference`, as a newer schema would write them.
  let struct$ = StructPointer(size: StructSize(safeDataBytes: 0, pointers: 1))
  let size = StructSize(safeDataBytes: 16, pointers: 2)
  let list = try #require(struct$.initList(at: 0, count: 2, elementSize: .composite(size)))
  #expect(list.initStruct(at: 1)!.write(UInt16(7), atByte: 0))

  let typed = try #require(List<TestSelfReference>(verifying: list))
  #expect(typed.read(at: 1).i == 7)
  #expect(typed[1].i == 7)
}

@Test
func streamDecoderByteByByte() throws {
  let bytes = [UInt8](try twoSegmentMessage().serialize())

  for chunkSize in [1, 2, 3, 5, 7, 13] {
    var decoder = MessageStreamDecoder()
    var decoded: Message?

    for start in stride(from: 0, to: bytes.count, by: chunkSize) {
      let end = min(start + chunkSize, bytes.count)
      let result = try decoder.push(bytes[start..<end])

      if end < bytes.count {
        try #require(result == nil)
      } else {
        let result = try #require(result)
        #expect(result.readBytes == end - start)
        decoded = result.message
      }
    }

    let root = try #require(decoded).root(of: TestValues.self)
    #expect(root.enum == .c)
    #expect(try root.ints()[1999] == 42)
  }
}

@Test
func streamDecoderMultipleRegions() throws {
  let bytes = [UInt8](try twoSegmentMessage().serialize())
  let half = bytes.count / 2

  var data = DispatchData.empty
  bytes[..<half].withUnsafeBytes { data.append($0) }
  (bytes[half...] + [0, 0, 0, 0]).withUnsafeBytes { data.append($0) }
  try #require(Array(data.regions).count == 2)

  var decoder = MessageStreamDecoder()
  let result = try #require(try decoder.push(data))

  #expect(result.readBytes == bytes.count)
}

@Test
func asyncStreamDecoder() async throws {
  func serialized(_ text: String) throws -> [UInt8] {
    let message = Message()
    _ = try #require(message.initRoot(of: TestValues.self).setText(Substring(text)))
    return [UInt8](message.serialize())
  }

  // Two messages of the same size followed by a longer one, in one chunk; then the start of a
  // message which ends in a second chunk.
  let fourth = try serialized("fourth")
  let firstChunk =
    try serialized("aaaa") + serialized("bbbb") + serialized("a longer message")
    + fourth[..<10]
  let secondChunk = fourth[10...]

  let chunks = AsyncThrowingStream<ArraySlice<UInt8>, any Error> { continuation in
    continuation.yield(firstChunk[...])
    continuation.yield(secondChunk)
    continuation.finish()
  }

  var texts: [String?] = []
  for try await message in Message.fromStream(chunks) {
    texts.append(try message.root(of: TestValues.self).text().toString())

    if texts.count > 10 {
      break
    }
  }

  #expect(texts == ["aaaa", "bbbb", "a longer message", "fourth"])
}

@Test
func emptyFirstSegment() throws {
  let bytes: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]

  #expect(throws: MessageStreamError.emptyFirstSegment) {
    _ = try Message.fromStream(data: bytes)
  }

  var decoder = MessageStreamDecoder()
  #expect(throws: MessageStreamError.emptyFirstSegment) {
    _ = try decoder.push(bytes)
  }

  var slowDecoder = MessageStreamDecoder()
  #expect(try slowDecoder.push(bytes[..<6]) == nil)
  #expect(throws: MessageStreamError.emptyFirstSegment) {
    _ = try slowDecoder.push(bytes[6...])
  }
}

/// Returns the stream framing of a message with `count` segments of one zero word each.
private func segmentHeader(count: Int) -> [UInt8] {
  var words: [UInt32] = [UInt32(count - 1)] + Array(repeating: 1, count: count)
  if words.count % 2 != 0 {
    words.append(0)  // Padding.
  }

  return words.withUnsafeBytes { Array($0) } + Array(repeating: 0, count: count * 8)
}

@Test
func zeroSizedStructEncoding() throws {
  let message = Message()
  _ = message.initRoot(size: .empty)

  // Offset -1, no data, no pointers.
  #expect(message.firstSegment.buffer[0] == 0xFFFF_FFFC)
  #expect(try message.rootPointer.resolve()?.expectStruct().size == .empty)
}

@Test
func listSubscriptIsChecked() async {
  await #expect(processExitsWith: .failure) {
    let list = TestValues().initInts(count: 1)!
    _ = list[1]
  }
}

@Test
func structListIsNeverNull() throws {
  let addressBook = AddressBook()
  let people = try #require(addressBook.initPeople(count: 1))

  #expect(!people.isNull(at: 0))
}

@Test
func bitListIsNotAStructList() throws {
  let message = Message(segmentWords: [listPointer(offset: 0, elementSize: 1, count: 8), 0xFF])!
  let bits = try #require(try message.rootPointer.resolve()?.expectList())

  // `TestValues.firstFieldSize` is `.twoBytes`; force a struct size check against bits.
  #expect(!bits.isCompatible(structSize: TestValues.size, firstFieldSize: .oneBit))
  #expect(throws: PointerError.unexpectedPointerType) {
    _ = try bits.readStruct(at: 0, firstFieldSize: .oneBit)
  }
}

@Test
func initListRejectsUnencodableCounts() throws {
  let struct$ = StructPointer(size: StructSize(safeDataBytes: 0, pointers: 1))

  #expect(struct$.initList(at: 0, count: -1, elementSize: .oneByte) == nil)
  #expect(struct$.initList(at: 0, count: 1 << 29, elementSize: .oneByte) == nil)
  // 2^28 elements of 2 words each need 2^29 words, which does not fit in 29 bits.
  #expect(
    struct$.initList(at: 0, count: 1 << 28, elementSize: .composite(.init(pointers: 2))) == nil
  )
  #expect(struct$.initList(at: 0, count: 3, elementSize: .oneByte)?.count == 3)
}

@Test
func borrowedSegmentsDoNotOutliveTheirBuffer() throws {
  let bytes = [UInt8](try twoSegmentMessage().serialize())
  let half = bytes.count / 2 / 8 * 8  // Keep the second half aligned.

  func withAlignedCopy<R>(
    of bytes: ArraySlice<UInt8>,
    _ body: (UnsafeRawBufferPointer) throws -> R
  ) rethrows -> R {
    let buffer = UnsafeMutableRawBufferPointer.allocate(
      byteCount: bytes.count,
      alignment: MemoryLayout<Word>.alignment
    )
    defer {
      // Scribble over the buffer before freeing it, so that dangling reads are visible.
      buffer.initializeMemory(as: UInt8.self, repeating: 0xAB)
      buffer.deallocate()
    }
    buffer.copyMemory(from: UnsafeRawBufferPointer(rebasing: bytes.withUnsafeBytes { $0 }[...]))

    return try body(UnsafeRawBufferPointer(buffer))
  }

  var decoder = MessageStreamDecoder()

  let first = try withAlignedCopy(of: bytes[..<half]) { try decoder.push(unsafeBorrowingFrom: $0) }
  #expect(first == nil)

  // The second half is borrowed while the message is decoded, so check it inside the closure.
  try withAlignedCopy(of: bytes[half...]) { buffer in
    let result = try #require(try decoder.push(unsafeBorrowingFrom: buffer))
    let root = try result.message.root(of: TestValues.self)

    #expect(root.enum == .c)
    #expect(try root.ints()[1999] == 42)
  }

  // A message borrowed entirely from one buffer is read-only.
  try withAlignedCopy(of: bytes[...]) { buffer in
    let result = try #require(try decoder.push(unsafeBorrowingFrom: buffer))

    #expect(result.message.isReadOnly)
    #expect(try result.message.root(of: TestValues.self).ints()[1999] == 42)
  }
}

@Test
func misalignedStreamInput() throws {
  let bytes = [UInt8](try twoSegmentMessage().serialize())
  let misaligned = [0] + bytes

  // `fromStream(data:)` copies, so it accepts misaligned input.
  let message = try Message.fromStream(data: misaligned[1...])
  #expect(try message.root(of: TestValues.self).ints()[1999] == 42)

  // The decoder copies misaligned input instead of borrowing it.
  var decoder = MessageStreamDecoder()
  let result = try misaligned.withUnsafeBytes { buffer in
    try decoder.push(unsafeBorrowingFrom: UnsafeRawBufferPointer(rebasing: buffer[1...]))
  }
  let decoded = try #require(result).message

  #expect(!decoded.isReadOnly)
  #expect(try decoded.root(of: TestValues.self).ints()[1999] == 42)
}

@Test
func fromStreamBorrowingIsReadOnly() throws {
  let bytes = [UInt8](try twoSegmentMessage().serialize())
  var words = [Word](repeating: 0, count: bytes.count / 8)
  words.withUnsafeMutableBytes { $0.copyMemory(from: UnsafeRawBufferPointer(start: bytes, count: bytes.count)) }

  try words.withUnsafeBufferPointer { buffer in
    let message = try Message.fromStream(unsafeBorrowingFrom: buffer)
    let root = try message.root(of: TestValues.self)

    #expect(message.isReadOnly)
    root.enum = .a  // No-op, as the message is read-only.
    #expect(root.enum == .c)
  }
}

@Test
func bitAndFloatListLayout() throws {
  let struct$ = StructPointer(size: StructSize(safeDataBytes: 0, pointers: 2))
  let bits: List<Bool> = try #require(struct$.initList(at: 0, count: 16))
  #expect(bits.write(true, at: 9))

  // Bit 9 is bit 1 of the second byte.
  let rawBits = try #require(try struct$.readList(at: 0, elementSize: .oneBit))
  #expect(rawBits.data.pointer.load(fromByteOffset: 1, as: UInt8.self) == 0b10)
  #expect(bits[9] && !bits[8] && !bits[1])

  let floats: List<Float64> = try #require(struct$.initList(at: 1, count: 2))
  #expect(floats.write(1.5, at: 1))
  #expect(floats[1] == 1.5)
  #expect(floats[0] == 0)
}
