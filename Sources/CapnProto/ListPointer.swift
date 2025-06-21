/// A list of elements in a `Message`.
public struct ListPointer: MessagePointer, Freezable {
  /// A pointer to the first element of the list.
  private(set) public var data: UnsafeMessagePointer
  /// The size of each element in the list.
  public let elementSize: ListElementSize
  /// The number of elements in the list.
  public let rawCount: UInt32

  public var count: Int { Int(rawCount) }
  public var isEmpty: Bool { count == 0 }

  /// Constructs an empty `ListPointer` of non-composite values.
  public init(elementSize: ListElementSize) {
    self.init(data: .null.value, elementSize: elementSize, count: 0)
  }

  /// Constructs an empty `ListPointer` of structs.
  public init(compositeSize: StructSize) {
    self.init(data: .null.value, compositeSize: compositeSize, count: 0)
  }

  public init(data: UnsafeMessagePointer, elementSize: ListElementSize, count: UInt32) {
    self.data = data
    self.elementSize = elementSize
    self.rawCount = count
  }

  public init(data: UnsafeMessagePointer, compositeSize: StructSize, count: UInt32) {
    self.data = data
    self.elementSize = .composite(compositeSize)
    self.rawCount = count
  }

  /// Returns a (shallow) copy of this list, but preventing mutations.
  public func asReadOnly() -> ListPointer {
    .init(
      data: data.asReadOnly(),
      elementSize: elementSize,
      count: rawCount
    )
  }

  public mutating func freeze() -> Frozen<ListPointer> {
    .init(
      unsafeFrozen: .init(
        data: data.freeze().value,
        elementSize: elementSize,
        count: rawCount
      )
    )
  }

  public var step: Int {
    switch elementSize {
    case .zero: 0
    case .oneBit: 1
    case .oneByte: 1
    case .twoBytes: 2
    case .fourBytes: 4
    case .eightBytes: 8
    case .pointer: 8
    case .composite(let size): Int(size.sizeInBytes)
    }
  }

  public subscript(range: Range<Int>) -> ListPointer {
    precondition(range.lowerBound >= 0 && range.upperBound <= count)

    return .init(
      data: data.advanced(byBytes: range.lowerBound * step),
      elementSize: elementSize,
      count: UInt32(range.count)
    )
  }
  public subscript(range: PartialRangeFrom<Int>) -> ListPointer {
    precondition(range.lowerBound >= 0 && range.lowerBound <= count)

    return .init(
      data: data.advanced(byBytes: range.lowerBound * step),
      elementSize: elementSize,
      count: rawCount - UInt32(range.lowerBound)
    )
  }
  public subscript(range: PartialRangeUpTo<Int>) -> ListPointer {
    precondition(range.upperBound >= 0 && range.upperBound <= count)

    return .init(
      data: data,
      elementSize: elementSize,
      count: UInt32(range.upperBound)
    )
  }

  /// Reads the element at the given index, which must be under `count`.
  public func read<T: ListElement>(at index: Int, of type: T.Type = T.self) throws(T.DecodeError)
    -> T
  {
    precondition(index >= 0 && index < count)
    precondition(T.elementSize == elementSize)

    return try T.read(in: self, uncheckedAt: index)
  }

  /// Writes the element at the given index, which must be under `count`.
  public func write<T: PrimitiveListElement>(_ value: T, at index: Int) -> Bool {
    precondition(index >= 0 && index < count)
    precondition(T.elementSize == elementSize)

    guard !data.isReadOnly else {
      return false
    }

    T.write(in: self, uncheckedAt: index, value: value)

    return true
  }

  /// Writes the string value at the given index, which must be under `count`.
  public func write(_ value: String, at index: Int) -> Bool {
    var value = value

    return value.withUTF8 { bytes in
      guard let list = initList(n: bytes.count, at: index, of: UInt8.self) else {
        return false
      }

      bytes.copyBytes(to: list.mutableBytes())

      return true
    }
  }

  /// Returns whether the element at the given index is null, which must be under `count`.
  public func isNull(at index: Int) -> Bool { pointer(at: index).read() == 0 }

  /// Returns whether this list can be interpreted as a list of structs of the given size (and
  /// first field size).
  public func isCompatible(structSize: StructSize, firstFieldSize: ListElementSize?) -> Bool {
    if elementSize.rawValue == .composite {
      // Struct list: all okay.
      return true
    }

    // Keep this check in sync with `readStruct()` below.
    guard let firstFieldSize else { return false }

    return firstFieldSize.rawValue == elementSize.rawValue
  }

  public func isCompatible<T: ListElement>(with type: T.Type = T.self) -> Bool {
    if case .composite(let size) = T.elementSize {
      isCompatible(structSize: size, firstFieldSize: T.firstFieldSize)
    } else {
      T.elementSize == elementSize
    }
  }

  public func initList(n: Int, elementSize: ListElementSize, at index: Int) -> ListPointer? {
    guard !data.isReadOnly else { return nil }

    let pointer = pointer(at: index)

    return pointer.initList(count: UInt32(n), elementSize: elementSize)
  }

  public func initList<T: ListElement>(n: Int, at index: Int, of type: T.Type = T.self)
    -> List<T>?
  {
    guard let list = initList(n: n, elementSize: T.elementSize, at: index) else { return nil }

    return .init(unchecked: list)
  }

  public func readStruct(at index: Int, firstFieldSize: ListElementSize?) throws(PointerError)
    -> StructPointer
  {
    precondition(index >= 0 && index < count)

    if elementSize.rawValue != .composite {
      // List is not a list of structs, but a list of primitives. This is allowed, and
      // indicates a list of structs with a single starting field.
      //
      // Keep this check in sync with `isCompatible()` above.
      guard let firstFieldSize, firstFieldSize.rawValue == elementSize.rawValue else {
        throw .unexpectedPointerType
      }
    }

    return switch elementSize {
    case .zero:
      .init()

    case .oneBit, .oneByte:
      .init(
        data: data.advanced(byBytes: index),
        size: .init(dataBytes: 1)
      )

    case .twoBytes:
      .init(
        data: data.advanced(byBytes: index * 2),
        size: .init(dataBytes: 2)
      )

    case .fourBytes:
      .init(
        data: data.advanced(byBytes: index * 4),
        size: .init(dataBytes: 4)
      )

    case .eightBytes:
      .init(
        data: data.advanced(byBytes: index * 8),
        size: .init(dataBytes: 8)
      )

    case .pointer:
      .init(
        data: data.advanced(byBytes: index * 8),
        size: .init(pointers: 1)
      )

    case .composite(let size):
      .init(data: data.advanced(byBytes: size.sizeInBytes * index), size: size)
    }
  }

  /// Initializes a struct at the given index, which must be under `count`.
  public func initStruct(at index: Int) -> StructPointer? {
    precondition(index >= 0 && index < count)

    guard !data.isReadOnly, index < count else { return nil }

    return switch elementSize {
    case .zero:
      StructPointer(data: data, size: .empty)

    case .oneBit, .oneByte:
      StructPointer(
        data: data.advanced(byBytes: index),
        size: .init(dataBytes: 1)
      )

    case .twoBytes:
      StructPointer(
        data: data.advanced(byBytes: index * 2),
        size: .init(dataBytes: 2)
      )

    case .fourBytes:
      StructPointer(
        data: data.advanced(byBytes: index * 4),
        size: .init(dataBytes: 4)
      )

    case .eightBytes:
      StructPointer(
        data: data.advanced(byBytes: index * 8),
        size: .init(dataBytes: 8)
      )

    case .pointer:
      StructPointer(
        data: data.advanced(byBytes: index * 8),
        size: .init(pointers: 1)
      )

    case .composite(let size):
      StructPointer(data: data.advanced(byBytes: index * size.sizeInBytes), size: size)
    }
  }

  /// Initializes a struct at the given index, which must be under `count`.
  public func initStruct<T: Struct>(at index: Int, of type: T.Type = T.self) -> T? {
    guard let struct$ = initStruct(at: index) else { return nil }
    return .init(struct$)
  }

  /// Returns the pointer at the given index, which must be under `count`.
  internal func pointer(at index: Int) -> AnyPointer {
    precondition(index >= 0 && index < count)
    precondition(elementSize == .pointer)

    return AnyPointer(unsafePointer: data.advanced(byBytes: index * 8))
  }
}
