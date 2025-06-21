/// A capability in a `Message`.
public struct AnyCapability {
  /// The index of the capability in the message's capability table.
  public let capabilityIndex: UInt32

  public init(capabilityIndex: UInt32) {
    self.capabilityIndex = capabilityIndex
  }
}

extension AnyCapability: Freezable {
  public func asReadOnly() -> AnyCapability {
    .init(capabilityIndex: capabilityIndex)
  }

  public mutating func freeze() -> Frozen<AnyCapability> {
    .init(unsafeFrozen: .init(capabilityIndex: capabilityIndex))
  }
}
