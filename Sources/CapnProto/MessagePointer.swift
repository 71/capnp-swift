/// Protocol implemented by message pointers.
public protocol MessagePointer: Freezable {
  /// Returns a (shallow) copy of this value, but preventing mutations.
  func asReadOnly() -> Self
}
