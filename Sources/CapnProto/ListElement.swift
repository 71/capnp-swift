/// An element of a `List`.
public protocol ListElement {
  /// Error type thrown when reading an element from a `List`.
  associatedtype DecodeError: Error = Never
  /// Type of a value returned by `readNonThrowing()`.
  associatedtype Result = Self

  /// The known size of the element in the list.
  static var elementSize: ListElementSize { get }
  /// The size of the first field in the struct if a list of this field can be interpreted as a list
  /// of this struct. Only set for structs.
  static var firstFieldSize: ListElementSize? { get }

  /// Reads the element at the given index, which must be under `count`.
  static func read(in list: ListPointer, uncheckedAt index: Int) throws(DecodeError) -> Self
  /// Same as `read(in:at:)`, but does not throw an error.
  static func readNonThrowing(in list: ListPointer, uncheckedAt index: Int) -> Result
}

/// A `ListElement`, except for `Bool`.
public protocol NonBitListElement: ListElement {}

// -------------------------------------------------------------------------------------------------
// MARK: PrimitiveListElement

/// A primitive element of a `List` which can be mutated directly.
public protocol PrimitiveListElement: ListElement where DecodeError == Never, Result == Self {
  static func write(in list: ListPointer, uncheckedAt index: Int, value: Self)
}

extension PrimitiveListElement {
  public static var firstFieldSize: ListElementSize? { nil }

  public static func readNonThrowing(in list: ListPointer, uncheckedAt index: Int) -> Self {
    read(in: list, uncheckedAt: index)
  }
}

/// An empty value used to represent a `Void` list element, needed as `Void` cannot be extended to
/// implement a protocol.
public struct VoidValue: PrimitiveListElement, NonBitListElement, Sendable {
  public static var elementSize: ListElementSize { .zero }

  public init() {}

  public static func read(in list: ListPointer, uncheckedAt index: Int) -> Self { .init() }
  public static func write(in list: ListPointer, uncheckedAt index: Int, value: Self) {}
}

extension Bool: PrimitiveListElement {
  public static var elementSize: ListElementSize { .oneBit }

  public static func read(in list: ListPointer, uncheckedAt index: Int) -> Bool {
    let (wordOffset, bitOffset) = index.quotientAndRemainder(dividingBy: Word.bitWidth)
    let word = list.data.pointer.load(
      fromByteOffset: wordOffset * MemoryLayout<Word>.size,
      as: Word.self
    )

    return (word & (1 << bitOffset)) != 0
  }

  public static func write(in list: ListPointer, uncheckedAt index: Int, value: Bool) {
    let (wordOffset, bitOffset) = index.quotientAndRemainder(dividingBy: Word.bitWidth)
    let wordAddress = list.data.assertMutablePointer.bindMemory(to: Word.self, capacity: 1)
      .advanced(by: wordOffset)

    if value {
      wordAddress.pointee |= (1 << bitOffset)
    } else {
      wordAddress.pointee &= ~(1 << bitOffset)
    }
  }
}

extension Int8: PrimitiveListElement, NonBitListElement {
  public static var elementSize: ListElementSize { .oneByte }

  public static func read(in list: ListPointer, uncheckedAt index: Int) -> Int8 {
    list.data.pointer.load(fromByteOffset: index, as: Int8.self)
  }

  public static func write(in list: ListPointer, uncheckedAt index: Int, value: Int8) {
    list.data.assertMutablePointer.storeBytes(of: value, toByteOffset: index, as: Int8.self)
  }
}

extension UInt8: PrimitiveListElement, NonBitListElement {
  public static var elementSize: ListElementSize { .oneByte }

  public static func read(in list: ListPointer, uncheckedAt index: Int) -> UInt8 {
    list.data.pointer.load(fromByteOffset: index, as: UInt8.self)
  }

  public static func write(in list: ListPointer, uncheckedAt index: Int, value: UInt8) {
    list.data.assertMutablePointer.storeBytes(of: value, toByteOffset: index, as: UInt8.self)
  }
}

extension Int16: PrimitiveListElement, NonBitListElement {
  public static var elementSize: ListElementSize { .twoBytes }

  public static func read(in list: ListPointer, uncheckedAt index: Int) -> Int16 {
    list.data.pointer.loadLe(fromByteOffset: index * 2, as: Int16.self)
  }

  public static func write(in list: ListPointer, uncheckedAt index: Int, value: Int16) {
    list.data.assertMutablePointer.storeBytes(
      of: value.littleEndian,
      toByteOffset: index * 2,
      as: Int16.self
    )
  }
}

extension UInt16: PrimitiveListElement, NonBitListElement {
  public static var elementSize: ListElementSize { .twoBytes }

  public static func read(in list: ListPointer, uncheckedAt index: Int) -> UInt16 {
    list.data.pointer.loadLe(fromByteOffset: index * 2, as: UInt16.self)
  }

  public static func write(in list: ListPointer, uncheckedAt index: Int, value: UInt16) {
    list.data.assertMutablePointer.storeBytes(
      of: value.littleEndian,
      toByteOffset: index * 2,
      as: UInt16.self
    )
  }
}

extension Int32: PrimitiveListElement, NonBitListElement {
  public static var elementSize: ListElementSize { .fourBytes }

  public static func read(in list: ListPointer, uncheckedAt index: Int) -> Int32 {
    list.data.pointer.loadLe(fromByteOffset: index * 4, as: Int32.self)
  }

  public static func write(in list: ListPointer, uncheckedAt index: Int, value: Int32) {
    list.data.assertMutablePointer.storeBytes(
      of: value.littleEndian,
      toByteOffset: index * 4,
      as: Int32.self
    )
  }
}

extension UInt32: PrimitiveListElement, NonBitListElement {
  public static var elementSize: ListElementSize { .fourBytes }

  public static func read(in list: ListPointer, uncheckedAt index: Int) -> UInt32 {
    list.data.pointer.loadLe(fromByteOffset: index * 4, as: UInt32.self)
  }

  public static func write(in list: ListPointer, uncheckedAt index: Int, value: UInt32) {
    list.data.assertMutablePointer.storeBytes(
      of: value.littleEndian,
      toByteOffset: index * 4,
      as: UInt32.self
    )
  }
}

extension Int64: PrimitiveListElement, NonBitListElement {
  public static var elementSize: ListElementSize { .eightBytes }

  public static func read(in list: ListPointer, uncheckedAt index: Int) -> Int64 {
    list.data.pointer.loadLe(fromByteOffset: index * 8, as: Int64.self)
  }

  public static func write(in list: ListPointer, uncheckedAt index: Int, value: Int64) {
    list.data.assertMutablePointer.storeBytes(
      of: value.littleEndian,
      toByteOffset: index * 8,
      as: Int64.self
    )
  }
}

extension UInt64: PrimitiveListElement, NonBitListElement {
  public static var elementSize: ListElementSize { .eightBytes }

  public static func read(in list: ListPointer, uncheckedAt index: Int) -> UInt64 {
    list.data.pointer.loadLe(fromByteOffset: index * 8, as: UInt64.self)
  }

  public static func write(in list: ListPointer, uncheckedAt index: Int, value: UInt64) {
    list.data.assertMutablePointer.storeBytes(
      of: value.littleEndian,
      toByteOffset: index * 8,
      as: UInt64.self
    )
  }
}

extension Float32: PrimitiveListElement, NonBitListElement {
  public static var elementSize: ListElementSize { .fourBytes }

  public static func read(in list: ListPointer, uncheckedAt index: Int) -> Float32 {
    list.data.pointer.load(fromByteOffset: index * 4, as: Float32.self)
  }

  public static func write(in list: ListPointer, uncheckedAt index: Int, value: Float32) {
    list.data.assertMutablePointer.storeBytes(
      of: value,
      toByteOffset: index * 4,
      as: Float32.self
    )
  }
}

extension Float64: PrimitiveListElement, NonBitListElement {
  public static var elementSize: ListElementSize { .eightBytes }

  public static func read(in list: ListPointer, uncheckedAt index: Int) -> Float64 {
    list.data.pointer.load(fromByteOffset: index * 8, as: Float64.self)
  }

  public static func write(in list: ListPointer, uncheckedAt index: Int, value: Float64) {
    list.data.assertMutablePointer.storeBytes(
      of: value,
      toByteOffset: index * 8,
      as: Float64.self
    )
  }
}

extension EnumValue: PrimitiveListElement {
  public static var elementSize: ListElementSize { .twoBytes }

  public static func read(in list: ListPointer, uncheckedAt index: Int) -> EnumValue<E> {
    .init(UInt16.read(in: list, uncheckedAt: index))
  }

  public static func write(in list: ListPointer, uncheckedAt index: Int, value: EnumValue<E>) {
    UInt16.write(in: list, uncheckedAt: index, value: value.rawValue)
  }
}

// -------------------------------------------------------------------------------------------------
// MARK: PointerListElement

/// A pointer element of a `List`.
public protocol PointerListElement: NonBitListElement, MessagePointer
where DecodeError == PointerError, Result == Swift.Result<Self, PointerError> {
}

extension PointerListElement {
  public static var firstFieldSize: ListElementSize? { nil }

  public static func readNonThrowing(in list: ListPointer, uncheckedAt index: Int)
    -> Swift.Result<Self, PointerError>
  {
    .init { () throws(PointerError) in try read(in: list, uncheckedAt: index) }
  }
}

extension AnyPointer: PointerListElement {
  public static var elementSize: ListElementSize { .pointer }

  public static func read(in list: ListPointer, uncheckedAt index: Int) throws(PointerError)
    -> AnyPointer
  {
    .init(unsafePointer: list.data.advanced(byBytes: index * 8))
  }
}

extension AnyCapability: PointerListElement {
  public static var elementSize: ListElementSize { .pointer }

  public static func read(in list: ListPointer, uncheckedAt index: Int) throws(PointerError)
    -> AnyCapability
  {
    try AnyPointer.read(in: list, uncheckedAt: index).resolve()?.expectCapability()
      ?? .init(capabilityIndex: 0)
  }
}

extension List: PointerListElement {
  public static var elementSize: ListElementSize { .pointer }

  public static func read(in list: ListPointer, uncheckedAt index: Int) throws(PointerError) -> List
  {
    if let list$ = try AnyPointer.read(in: list, uncheckedAt: index).resolve()?.expectList() {
      .init(unchecked: list$)
    } else {
      .init()
    }
  }
}

extension Text: PointerListElement {
  public static var elementSize: ListElementSize { .pointer }

  public static func read(in list: ListPointer, uncheckedAt index: Int) throws(PointerError) -> Text
  {
    .init(try List<UInt8>.read(in: list, uncheckedAt: index))
  }
}

// -------------------------------------------------------------------------------------------------
// MARK: ListElement for Struct

/// Implementation of `ListElement` for `Struct`s.
extension Struct {
  public static var elementSize: ListElementSize { .composite(size) }

  public static func read(in list: ListPointer, uncheckedAt index: Int) -> Self {
    // We use `try!` because the caller is expected to have checked that this access is valid with
    // `isCompatible()`.
    return .init(try! list.readStruct(at: index, firstFieldSize: firstFieldSize))
  }

  public static func readNonThrowing(in list: ListPointer, uncheckedAt index: Int) -> Self {
    read(in: list, uncheckedAt: index)
  }
}
