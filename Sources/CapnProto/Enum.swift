/// Protocol adopted by Cap'n Proto enums.
public protocol Enum: EnumOrDiscriminant, SchemaEntity {}

/// Protocol adopted by `Enum`s and `Struct` union discriminants.
public protocol EnumOrDiscriminant: RawRepresentable<UInt16>, Sendable, Comparable {
  static var defaultValue: Self { get }
  static var maxValue: Self { get }
}

/// Implementation of `Comparable` for `EnumOrDiscriminant`.
extension EnumOrDiscriminant {
  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

// -------------------------------------------------------------------------------------------------
// MARK: EnumValue

/// A wrapper around an `Enum` which supports unknown values.
public struct EnumValue<E: EnumOrDiscriminant>: Sendable, Equatable, Hashable {
  /// The raw value of the enum.
  public var rawValue: UInt16

  /// Yields the enum value, or its default value if it is not part of the schema.
  public var orDefault: E { .init(rawValue: rawValue) ?? E.defaultValue }

  /// Yields the enum value, or nil if it is not part of the schema.
  public var orNil: E? { .init(rawValue: rawValue) }

  /// Constructs a default value.
  public init() { self.rawValue = E.defaultValue.rawValue }

  /// Constructs a value from a raw value.
  public init(_ rawValue: UInt16) { self.rawValue = rawValue }

  /// Constructs a value from a valid enum value.
  public init(_ value: E) { self.rawValue = value.rawValue }

  /// Sets the enum value.
  public mutating func set(_ value: E) { rawValue = value.rawValue }
}

extension EnumValue: Comparable {
  public static func < (lhs: EnumValue<E>, rhs: EnumValue<E>) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

extension EnumValue: CustomStringConvertible where E: CustomStringConvertible {
  public var description: String {
    orNil?.description ?? "0x\(String(rawValue, radix: 16))"
  }
}
