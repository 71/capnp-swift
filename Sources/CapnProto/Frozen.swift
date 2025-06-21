/// A wrapper around a struct which guarantees that it won't be mutated, thus making it safe to
/// share across threads.
public struct Frozen<T: Freezable>: @unchecked Sendable {
  /// The underlying struct.
  public let value: T

  /// Constructs a frozen wrapper around the given value. The caller must ensure that the value
  /// cannot be mutated.
  internal init(unsafeFrozen value: T) { self.value = value }

  /// Freezes the value returned by the given closure.
  public init(freeze value: () -> T) {
    var value = value()

    self = value.freeze()
  }
}

/// A protocol for entities that can be frozen (stored in a `Frozen<T>` wrapper).
public protocol Freezable {
  /// Freezes the value, making it immutable and safe to share across threads.
  ///
  /// If the underlying message is already frozen or if only referenced by the caller, it will
  /// be frozen in place. Otherwise, it will be copied to a new immutable message first.
  mutating func freeze() -> Frozen<Self>
}
