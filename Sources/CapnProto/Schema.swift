/// An entity in a Cap'n Proto schema.
public protocol SchemaEntity {
  /// The unique identifier of the entity.
  static var id: UInt64 { get }
}
