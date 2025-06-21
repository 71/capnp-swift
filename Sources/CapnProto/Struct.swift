/// Protocol adopted by generated Cap'n Proto structs.
public protocol Struct: MessagePointer, SchemaEntity, ListElement, Freezable
where Self.DecodeError == Never {
  static var size: StructSize { get }

  var struct$: StructPointer { get set }

  init(_ struct$: StructPointer)
}

extension Struct {
  public init() { self.init(StructPointer(size: Self.size)) }

  public static func readOnly() -> Self {
    var inner = StructPointer()
    return .init(inner.freeze().value)
  }
}

/// Implementation of `MessagePointer` and `Freezable` for `Struct`s.
extension Struct {
  /// Returns a (shallow) copy of this struct, but preventing mutations.
  public func asReadOnly() -> Self { Self.init(struct$.asReadOnly()) }

  /// Freezes this struct, returning a frozen version of it.
  ///
  /// If the underlying message is referenced by other structs, a copy of the message will be
  /// made.
  public mutating func freeze() -> Frozen<Self> {
    .init(unsafeFrozen: .init(struct$.freeze().value))
  }
}
