/// A list of elements of type `T` in a `Message`.
public struct List<T: ListElement>: MessagePointer, Freezable {
  /// The underlying untyped list.
  private(set) public var list$: ListPointer

  /// Returns the number of elements in the list.
  public var count: Int { list$.count }

  public var isEmpty: Bool { count == 0 }

  /// Constructs an empty `List`.
  public init() { self.list$ = .init(elementSize: T.elementSize) }

  /// Constructs a `List` from an `ListPointer` if the element size matches `T.size`.
  public init?(verifying list: ListPointer) {
    guard list.isCompatible(with: T.self) else { return nil }

    self.list$ = list
  }

  public init(unchecked list$: ListPointer) {
    assert(list$.isCompatible(with: T.self))

    self.list$ = list$
  }

  public static func readOnly() -> List<T> {
    .init(unchecked: .init(data: .readOnly(words: []), elementSize: T.elementSize, count: 0))
  }

  /// Returns a (shallow) copy of this list, but preventing mutations.
  public func asReadOnly() -> List<T> { .init(unchecked: list$.asReadOnly()) }

  public mutating func freeze() -> Frozen<List<T>> {
    .init(unsafeFrozen: .init(unchecked: list$.freeze().value))
  }

  /// Returns the element at the given index, which must be under `count`.
  public func read(at index: Int) throws(T.DecodeError) -> T {
    try list$.read(at: index)
  }

  /// Writes the element at the given index, which must be under `count`.
  public func write(_ value: T, at index: Int) -> Bool where T: PrimitiveListElement {
    list$.write(value, at: index)
  }

  /// Writes the string value at the given index, which must be under `count`.
  public func write(_ value: String, at index: Int) -> Bool where T == Text {
    list$.write(value, at: index)
  }

  /// Returns a mutable buffer pointer to the bytes of the list.
  public func bytes() -> UnsafeBufferPointer<UInt8> where T == UInt8 {
    .init(
      start: list$.data.pointer.assumingMemoryBound(to: UInt8.self),
      count: count
    )
  }

  /// Returns a mutable buffer pointer to the bytes of the list, or an empty nil buffer if the
  /// list is read-only.
  public func mutableBytes() -> UnsafeMutableBufferPointer<UInt8> where T == UInt8 {
    if let mutablePointer = list$.data.mutablePointer {
      .init(
        start: mutablePointer.assumingMemoryBound(to: UInt8.self),
        count: count
      )
    } else {
      .init(start: nil, count: 0)
    }
  }

  /// Returns whether the element at the given index is null, which must be under `count`.
  public func isNull(at index: Int) -> Bool where T: MessagePointer {
    list$.isNull(at: index)
  }

  /// Initializes a struct at the given index, which must be under `count`.
  public func initialize(at index: Int) -> T? where T: Struct {
    list$.initStruct(at: index)
  }

  /// Initializes a list of `n` elements at the given index, which must be under `count`.
  public func initialize<U: ListElement>(n: Int, at index: Int) -> T? where T == List<U> {
    list$.initList(n: n, at: index)
  }
}

// Providing a sub-range of the list is unsafe if `T == Bool`, so we don't.
extension List where T: NonBitListElement {
  public subscript(range: Range<Int>) -> Self {
    .init(unchecked: list$[range])
  }
  public subscript(range: PartialRangeFrom<Int>) -> Self {
    .init(unchecked: list$[range])
  }
  public subscript(range: PartialRangeUpTo<Int>) -> Self {
    .init(unchecked: list$[range])
  }
}

// -------------------------------------------------------------------------------------------------
// MARK: Collection (List)

// Adopting `Collection` with an `Int` `Index` will automatically adopt `Sequence`.
extension List: Collection, BidirectionalCollection, RandomAccessCollection {
  public var startIndex: Int { 0 }
  public var endIndex: Int { count }

  public subscript(position: Int) -> T.Result {
    T.readNonThrowing(in: list$, uncheckedAt: position)
  }

  public func index(after i: Int) -> Int { i + 1 }
}

extension List: MutableCollection where T: PrimitiveListElement {
  public subscript(position: Int) -> T {
    get { read(at: position) }
    nonmutating set { _ = write(newValue, at: position) }
  }
}
