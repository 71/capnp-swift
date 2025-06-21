// Automatically generated from Sources/CapnProtoSchema/schema.capnp @0xa93fc509624c72d9.
// See https://github.com/71/capnp-swift for more information.
//
// swift-format-ignore-file
import CapnProto

public struct CapnProtoSchema$ {
  public typealias Annotation = CapnProtoSchema.Annotation
}

public struct Node: CapnProto.Struct {
  public static let id: UInt64 = 0xe682ab4cf923a417
  public static let size: CapnProto.StructSize = .init(safeDataBytes: 48, pointers: 6)
  public static let firstFieldSize: CapnProto.ListElementSize? = .eightBytes

  /// Information about one of the node's parameters.
  public struct Parameter: CapnProto.Struct {
    public static let id: UInt64 = 0xb9521bccf10fa3b1
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 0, pointers: 1)
    public static let firstFieldSize: CapnProto.ListElementSize? = .pointer

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    public func name() throws(CapnProto.PointerError) -> CapnProto.Text {
      try struct$.readText(at: 0) ?? .init()
    }

    public func setName(_ text: Substring) -> CapnProto.Text? {
      struct$.writeText(text, at: 0)
    }
  }

  public struct NestedNode: CapnProto.Struct {
    public static let id: UInt64 = 0xdebf55bbfa0fc242
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 8, pointers: 1)
    public static let firstFieldSize: CapnProto.ListElementSize? = .pointer

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    /// Unqualified symbol name.  Unlike Node.displayName, this *can* be used programmatically.
    ///
    /// (On Zooko's triangle, this is the node's petname according to its parent scope.)
    public func name() throws(CapnProto.PointerError) -> CapnProto.Text {
      try struct$.readText(at: 0) ?? .init()
    }

    public func setName(_ text: Substring) -> CapnProto.Text? {
      struct$.writeText(text, at: 0)
    }

    /// ID of the nested node.  Typically, the target node's scopeId points back to this node, but
    /// robust code should avoid relying on this.
    public var id: UInt64 {
      get { struct$.read(atByte: 0) }
      nonmutating set { _ = struct$.write(newValue, atByte: 0) }
    }
  }

  /// Additional information about a node which is not needed at runtime, but may be useful for
  /// documentation or debugging purposes. This is kept in a separate struct to make sure it
  /// doesn't accidentally get included in contexts where it is not needed. The
  /// `CodeGeneratorRequest` includes this information in a separate array.
  public struct SourceInfo: CapnProto.Struct {
    public static let id: UInt64 = 0xf38e1de3041357ae
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 16, pointers: 2)
    public static let firstFieldSize: CapnProto.ListElementSize? = .eightBytes

    public struct Member: CapnProto.Struct {
      public static let id: UInt64 = 0xc2ba9038898e1fa2
      public static let size: CapnProto.StructSize = .init(safeDataBytes: 8, pointers: 1)
      public static let firstFieldSize: CapnProto.ListElementSize? = .pointer

      public var struct$: CapnProto.StructPointer

      public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

      /// Doc comment on the member.
      public func docComment() throws(CapnProto.PointerError) -> CapnProto.Text {
        try struct$.readText(at: 0) ?? .init()
      }

      public func setDocComment(_ text: Substring) -> CapnProto.Text? {
        struct$.writeText(text, at: 0)
      }

      public var startByte: UInt32 {
        get { struct$.read(atByte: 0) }
        nonmutating set { _ = struct$.write(newValue, atByte: 0) }
      }

      public var endByte: UInt32 {
        get { struct$.read(atByte: 4) }
        nonmutating set { _ = struct$.write(newValue, atByte: 4) }
      }
    }

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    /// ID of the Node which this info describes.
    public var id: UInt64 {
      get { struct$.read(atByte: 0) }
      nonmutating set { _ = struct$.write(newValue, atByte: 0) }
    }

    /// The top-level doc comment for the Node.
    public func docComment() throws(CapnProto.PointerError) -> CapnProto.Text {
      try struct$.readText(at: 0) ?? .init()
    }

    public func setDocComment(_ text: Substring) -> CapnProto.Text? {
      struct$.writeText(text, at: 0)
    }

    /// Information about each member -- i.e. fields (for structs), enumerants (for enums), or
    /// methods (for interfaces).
    ///
    /// This list is the same length and order as the corresponding list in the Node, i.e.
    /// Node.struct.fields, Node.enum.enumerants, or Node.interface.methods.
    public func members() throws(CapnProto.PointerError) -> CapnProto.List<Member> {
      try struct$.readList(at: 1) ?? .init()
    }

    public func initMembers(count: Int) -> CapnProto.List<Member>? {
      struct$.initList(at: 1, count: count)
    }

    public var startByte: UInt32 {
      get { struct$.read(atByte: 8) }
      nonmutating set { _ = struct$.write(newValue, atByte: 8) }
    }

    public var endByte: UInt32 {
      get { struct$.read(atByte: 12) }
      nonmutating set { _ = struct$.write(newValue, atByte: 12) }
    }
  }

  /// Generated for group `struct`.
  public struct Struct: CapnProto.Struct {
    public static let id: UInt64 = 0x9ea0b19b37fb4435
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 48, pointers: 6)
    public static let firstFieldSize: CapnProto.ListElementSize? = .twoBytes

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    /// Size of the data section, in words.
    public var dataWordCount: UInt16 {
      get { struct$.read(atByte: 14) }
      nonmutating set { _ = struct$.write(newValue, atByte: 14) }
    }

    /// Size of the pointer section, in pointers (which are one word each).
    public var pointerCount: UInt16 {
      get { struct$.read(atByte: 24) }
      nonmutating set { _ = struct$.write(newValue, atByte: 24) }
    }

    /// The preferred element size to use when encoding a list of this struct.  If this is anything
    /// other than `inlineComposite` then the struct is one word or less in size and is a candidate
    /// for list packing optimization.
    public var preferredListEncoding: CapnProto.EnumValue<ElementSize> {
      get { struct$.readEnum(atByte: 26) }
      nonmutating set { _ = struct$.writeEnum(newValue, atByte: 26) }
    }

    /// If true, then this "struct" node is actually not an independent node, but merely represents
    /// some named union or group within a particular parent struct.  This node's scopeId refers
    /// to the parent struct, which may itself be a union/group in yet another struct.
    ///
    /// All group nodes share the same dataWordCount and pointerCount as the top-level
    /// struct, and their fields live in the same ordinal and offset spaces as all other fields in
    /// the struct.
    ///
    /// Note that a named union is considered a special kind of group -- in fact, a named union
    /// is exactly equivalent to a group that contains nothing but an unnamed union.
    public var isGroup: Bool {
      get { struct$.read(atBit: 224) }
      nonmutating set { _ = struct$.write(newValue, atBit: 224) }
    }

    /// Number of fields in this struct which are members of an anonymous union, and thus may
    /// overlap.  If this is non-zero, then a 16-bit discriminant is present indicating which
    /// of the overlapping fields is active.  This can never be 1 -- if it is non-zero, it must be
    /// two or more.
    ///
    /// Note that the fields of an unnamed union are considered fields of the scope containing the
    /// union -- an unnamed union is not its own group.  So, a top-level struct may contain a
    /// non-zero discriminant count.  Named unions, on the other hand, are equivalent to groups
    /// containing unnamed unions.  So, a named union has its own independent schema node, with
    /// `isGroup` = true.
    public var discriminantCount: UInt16 {
      get { struct$.read(atByte: 30) }
      nonmutating set { _ = struct$.write(newValue, atByte: 30) }
    }

    /// If `discriminantCount` is non-zero, this is the offset of the union discriminant, in
    /// multiples of 16 bits.
    public var discriminantOffset: UInt32 {
      get { struct$.read(atByte: 32) }
      nonmutating set { _ = struct$.write(newValue, atByte: 32) }
    }

    /// Fields defined within this scope (either the struct's top-level fields, or the fields of
    /// a particular group; see `isGroup`).
    ///
    /// The fields are sorted by ordinal number, but note that because groups share the same
    /// ordinal space, the field's index in this list is not necessarily exactly its ordinal.
    /// On the other hand, the field's position in this list does remain the same even as the
    /// protocol evolves, since it is not possible to insert or remove an earlier ordinal.
    /// Therefore, for most use cases, if you want to identify a field by number, it may make the
    /// most sense to use the field's index in this list rather than its ordinal.
    public func fields() throws(CapnProto.PointerError) -> CapnProto.List<Field> {
      try struct$.readList(at: 3) ?? .init()
    }

    public func initFields(count: Int) -> CapnProto.List<Field>? {
      struct$.initList(at: 3, count: count)
    }
  }

  /// Generated for group `enum`.
  public struct Enum: CapnProto.Struct {
    public static let id: UInt64 = 0xb54ab3364333f598
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 48, pointers: 6)
    public static let firstFieldSize: CapnProto.ListElementSize? = .pointer

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    /// Enumerants ordered by numeric value (ordinal).
    public func enumerants() throws(CapnProto.PointerError) -> CapnProto.List<Enumerant> {
      try struct$.readList(at: 3) ?? .init()
    }

    public func initEnumerants(count: Int) -> CapnProto.List<Enumerant>? {
      struct$.initList(at: 3, count: count)
    }
  }

  /// Generated for group `interface`.
  public struct Interface: CapnProto.Struct {
    public static let id: UInt64 = 0xe82753cff0c2218f
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 48, pointers: 6)
    public static let firstFieldSize: CapnProto.ListElementSize? = .pointer

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    /// Methods ordered by ordinal.
    public func methods() throws(CapnProto.PointerError) -> CapnProto.List<Method> {
      try struct$.readList(at: 3) ?? .init()
    }

    public func initMethods(count: Int) -> CapnProto.List<Method>? {
      struct$.initList(at: 3, count: count)
    }

    /// Superclasses of this interface.
    public func superclasses() throws(CapnProto.PointerError) -> CapnProto.List<Superclass> {
      try struct$.readList(at: 4) ?? .init()
    }

    public func initSuperclasses(count: Int) -> CapnProto.List<Superclass>? {
      struct$.initList(at: 4, count: count)
    }
  }

  /// Generated for group `const`.
  public struct Const: CapnProto.Struct {
    public static let id: UInt64 = 0xb18aa5ac7a0d9420
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 48, pointers: 6)
    public static let firstFieldSize: CapnProto.ListElementSize? = .pointer

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    public func type() throws(CapnProto.PointerError) -> `Type` {
      try struct$.readStruct(at: 3) ?? .init()
    }

    public func initType() -> `Type`? {
      struct$.initStruct(at: 3)
    }

    public func value() throws(CapnProto.PointerError) -> Value {
      try struct$.readStruct(at: 4) ?? .init()
    }

    public func initValue() -> Value? {
      struct$.initStruct(at: 4)
    }
  }

  /// Generated for group `annotation`.
  public struct Annotation: CapnProto.Struct {
    public static let id: UInt64 = 0xec1619d4400a0290
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 48, pointers: 6)
    public static let firstFieldSize: CapnProto.ListElementSize? = .pointer

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    public func type() throws(CapnProto.PointerError) -> `Type` {
      try struct$.readStruct(at: 3) ?? .init()
    }

    public func initType() -> `Type`? {
      struct$.initStruct(at: 3)
    }

    public var targetsFile: Bool {
      get { struct$.read(atBit: 112) }
      nonmutating set { _ = struct$.write(newValue, atBit: 112) }
    }

    public var targetsConst: Bool {
      get { struct$.read(atBit: 113) }
      nonmutating set { _ = struct$.write(newValue, atBit: 113) }
    }

    public var targetsEnum: Bool {
      get { struct$.read(atBit: 114) }
      nonmutating set { _ = struct$.write(newValue, atBit: 114) }
    }

    public var targetsEnumerant: Bool {
      get { struct$.read(atBit: 115) }
      nonmutating set { _ = struct$.write(newValue, atBit: 115) }
    }

    public var targetsStruct: Bool {
      get { struct$.read(atBit: 116) }
      nonmutating set { _ = struct$.write(newValue, atBit: 116) }
    }

    public var targetsField: Bool {
      get { struct$.read(atBit: 117) }
      nonmutating set { _ = struct$.write(newValue, atBit: 117) }
    }

    public var targetsUnion: Bool {
      get { struct$.read(atBit: 118) }
      nonmutating set { _ = struct$.write(newValue, atBit: 118) }
    }

    public var targetsGroup: Bool {
      get { struct$.read(atBit: 119) }
      nonmutating set { _ = struct$.write(newValue, atBit: 119) }
    }

    public var targetsInterface: Bool {
      get { struct$.read(atBit: 120) }
      nonmutating set { _ = struct$.write(newValue, atBit: 120) }
    }

    public var targetsMethod: Bool {
      get { struct$.read(atBit: 121) }
      nonmutating set { _ = struct$.write(newValue, atBit: 121) }
    }

    public var targetsParam: Bool {
      get { struct$.read(atBit: 122) }
      nonmutating set { _ = struct$.write(newValue, atBit: 122) }
    }

    public var targetsAnnotation: Bool {
      get { struct$.read(atBit: 123) }
      nonmutating set { _ = struct$.write(newValue, atBit: 123) }
    }
  }

  public var struct$: CapnProto.StructPointer

  public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

  public enum Which {
    public enum Discriminant: UInt16, CapnProto.EnumOrDiscriminant {
      public static let defaultValue: Discriminant = .file
      public static let maxValue: Discriminant = .annotation

      case file = 0
      case `struct` = 1
      case `enum` = 2
      case interface = 3
      case const = 4
      case annotation = 5
    }

    case file
    case `struct`(Struct)
    case `enum`(Enum)
    case interface(Interface)
    case const(Const)
    case annotation(Annotation)
  }

  public var whichDiscriminant: CapnProto.EnumValue<Which.Discriminant> {
    struct$.readEnum(atByte: 12, defaultValue: .file)
  }

  public func which() -> Which? {
    switch whichDiscriminant.rawValue {
    case 0: .file
    case 1: .struct(.init(struct$))
    case 2: .enum(.init(struct$))
    case 3: .interface(.init(struct$))
    case 4: .const(.init(struct$))
    case 5: .annotation(.init(struct$))
    default: nil
    }
  }

  public var id: UInt64 {
    get { struct$.read(atByte: 0) }
    nonmutating set { _ = struct$.write(newValue, atByte: 0) }
  }

  /// Name to present to humans to identify this Node.  You should not attempt to parse this.  Its
  /// format could change.  It is not guaranteed to be unique.
  ///
  /// (On Zooko's triangle, this is the node's nickname.)
  public func displayName() throws(CapnProto.PointerError) -> CapnProto.Text {
    try struct$.readText(at: 0) ?? .init()
  }

  public func setDisplayName(_ text: Substring) -> CapnProto.Text? {
    struct$.writeText(text, at: 0)
  }

  /// If you want a shorter version of `displayName` (just naming this node, without its surrounding
  /// scope), chop off this many characters from the beginning of `displayName`.
  public var displayNamePrefixLength: UInt32 {
    get { struct$.read(atByte: 8) }
    nonmutating set { _ = struct$.write(newValue, atByte: 8) }
  }

  /// ID of the lexical parent node.  Typically, the scope node will have a NestedNode pointing back
  /// at this node, but robust code should avoid relying on this (and, in fact, group nodes are not
  /// listed in the outer struct's nestedNodes, since they are listed in the fields).  `scopeId` is
  /// zero if the node has no parent, which is normally only the case with files, but should be
  /// allowed for any kind of node (in order to make runtime type generation easier).
  public var scopeId: UInt64 {
    get { struct$.read(atByte: 16) }
    nonmutating set { _ = struct$.write(newValue, atByte: 16) }
  }

  /// List of nodes nested within this node, along with the names under which they were declared.
  public func nestedNodes() throws(CapnProto.PointerError) -> CapnProto.List<NestedNode> {
    try struct$.readList(at: 1) ?? .init()
  }

  public func initNestedNodes(count: Int) -> CapnProto.List<NestedNode>? {
    struct$.initList(at: 1, count: count)
  }

  /// Annotations applied to this node.
  public func annotations() throws(CapnProto.PointerError) -> CapnProto.List<CapnProtoSchema$.Annotation> {
    try struct$.readList(at: 2) ?? .init()
  }

  public func initAnnotations(count: Int) -> CapnProto.List<CapnProtoSchema$.Annotation>? {
    struct$.initList(at: 2, count: count)
  }

  /// Part of a union.
  public var file: CapnProto.VoidValue? {
    whichDiscriminant.rawValue == 0 ? .init() : nil
  }

  public func setFile() {
    _ = struct$.write(UInt16(0), atByte: 12)
  }

  /// Part of a union.
  public var `struct`: Struct? { whichDiscriminant.rawValue == 1 ? .init(struct$) : nil }

  public func initStruct() -> Struct {
    _ = struct$.write(UInt16(1), atByte: 12)
    _ = struct$.write(UInt16(0), atByte: 14)
    _ = struct$.write(UInt16(0), atByte: 24)
    _ = struct$.write(UInt16(0), atByte: 26)
    _ = struct$.write(false, atBit: 224)
    _ = struct$.write(UInt16(0), atByte: 30)
    _ = struct$.write(UInt32(0), atByte: 32)
    _ = struct$.write(UInt64(0), atByte: 24)
    return .init(struct$)
  }

  /// Part of a union.
  public var `enum`: Enum? { whichDiscriminant.rawValue == 2 ? .init(struct$) : nil }

  public func initEnum() -> Enum {
    _ = struct$.write(UInt16(2), atByte: 12)
    _ = struct$.write(UInt64(0), atByte: 24)
    return .init(struct$)
  }

  /// Part of a union.
  public var interface: Interface? { whichDiscriminant.rawValue == 3 ? .init(struct$) : nil }

  public func initInterface() -> Interface {
    _ = struct$.write(UInt16(3), atByte: 12)
    _ = struct$.write(UInt64(0), atByte: 24)
    _ = struct$.write(UInt64(0), atByte: 32)
    return .init(struct$)
  }

  /// Part of a union.
  public var const: Const? { whichDiscriminant.rawValue == 4 ? .init(struct$) : nil }

  public func initConst() -> Const {
    _ = struct$.write(UInt16(4), atByte: 12)
    _ = struct$.write(UInt64(0), atByte: 24)
    _ = struct$.write(UInt64(0), atByte: 32)
    return .init(struct$)
  }

  /// Part of a union.
  public var annotation: Annotation? { whichDiscriminant.rawValue == 5 ? .init(struct$) : nil }

  public func initAnnotation() -> Annotation {
    _ = struct$.write(UInt16(5), atByte: 12)
    _ = struct$.write(UInt64(0), atByte: 24)
    _ = struct$.write(false, atBit: 112)
    _ = struct$.write(false, atBit: 113)
    _ = struct$.write(false, atBit: 114)
    _ = struct$.write(false, atBit: 115)
    _ = struct$.write(false, atBit: 116)
    _ = struct$.write(false, atBit: 117)
    _ = struct$.write(false, atBit: 118)
    _ = struct$.write(false, atBit: 119)
    _ = struct$.write(false, atBit: 120)
    _ = struct$.write(false, atBit: 121)
    _ = struct$.write(false, atBit: 122)
    _ = struct$.write(false, atBit: 123)
    return .init(struct$)
  }

  /// If this node is parameterized (generic), the list of parameters. Empty for non-generic types.
  public func parameters() throws(CapnProto.PointerError) -> CapnProto.List<Parameter> {
    try struct$.readList(at: 5) ?? .init()
  }

  public func initParameters(count: Int) -> CapnProto.List<Parameter>? {
    struct$.initList(at: 5, count: count)
  }

  /// True if this node is generic, meaning that it or one of its parent scopes has a non-empty
  /// `parameters`.
  public var isGeneric: Bool {
    get { struct$.read(atBit: 288) }
    nonmutating set { _ = struct$.write(newValue, atBit: 288) }
  }

  public var startByte: UInt32 {
    get { struct$.read(atByte: 40) }
    nonmutating set { _ = struct$.write(newValue, atByte: 40) }
  }

  public var endByte: UInt32 {
    get { struct$.read(atByte: 44) }
    nonmutating set { _ = struct$.write(newValue, atByte: 44) }
  }
}

/// Schema for a field of a struct.
public struct Field: CapnProto.Struct {
  public static let id: UInt64 = 0x9aad50a41f4af45f
  public static let size: CapnProto.StructSize = .init(safeDataBytes: 24, pointers: 4)
  public static let firstFieldSize: CapnProto.ListElementSize? = .pointer

  public static let noDiscriminant: UInt16 =  // 0x97b14cbe7cfec712
    65535

  /// Generated for group `slot`.
  public struct Slot: CapnProto.Struct {
    public static let id: UInt64 = 0xc42305476bb4746f
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 24, pointers: 4)
    public static let firstFieldSize: CapnProto.ListElementSize? = .fourBytes

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    /// Offset, in units of the field's size, from the beginning of the section in which the field
    /// resides.  E.g. for a UInt32 field, multiply this by 4 to get the byte offset from the
    /// beginning of the data section.
    public var offset: UInt32 {
      get { struct$.read(atByte: 4) }
      nonmutating set { _ = struct$.write(newValue, atByte: 4) }
    }

    public func type() throws(CapnProto.PointerError) -> `Type` {
      try struct$.readStruct(at: 2) ?? .init()
    }

    public func initType() -> `Type`? {
      struct$.initStruct(at: 2)
    }

    public func defaultValue() throws(CapnProto.PointerError) -> Value {
      try struct$.readStruct(at: 3) ?? .init()
    }

    public func initDefaultValue() -> Value? {
      struct$.initStruct(at: 3)
    }

    /// Whether the default value was specified explicitly.  Non-explicit default values are always
    /// zero or empty values.  Usually, whether the default value was explicit shouldn't matter.
    /// The main use case for this flag is for structs representing method parameters:
    /// explicitly-defaulted parameters may be allowed to be omitted when calling the method.
    public var hadExplicitDefault: Bool {
      get { struct$.read(atBit: 128) }
      nonmutating set { _ = struct$.write(newValue, atBit: 128) }
    }
  }

  /// Generated for group `group`.
  public struct Group: CapnProto.Struct {
    public static let id: UInt64 = 0xcafccddb68db1d11
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 24, pointers: 4)
    public static let firstFieldSize: CapnProto.ListElementSize? = .eightBytes

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    /// The ID of the group's node.
    public var typeId: UInt64 {
      get { struct$.read(atByte: 16) }
      nonmutating set { _ = struct$.write(newValue, atByte: 16) }
    }
  }

  /// Generated for group `ordinal`.
  public struct Ordinal: CapnProto.Struct {
    public static let id: UInt64 = 0xbb90d5c287870be6
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 24, pointers: 4)
    public static let firstFieldSize: CapnProto.ListElementSize? = nil

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    public enum Which {
      public enum Discriminant: UInt16, CapnProto.EnumOrDiscriminant {
        public static let defaultValue: Discriminant = .implicit
        public static let maxValue: Discriminant = .explicit

        case implicit = 0
        case explicit = 1
      }

      case implicit
      case explicit(UInt16)
    }

    public var whichDiscriminant: CapnProto.EnumValue<Which.Discriminant> {
      struct$.readEnum(atByte: 10, defaultValue: .implicit)
    }

    public func which() -> Which? {
      switch whichDiscriminant.rawValue {
      case 0: .implicit
      case 1: .explicit(struct$.read(atByte: 12))
      default: nil
      }
    }

    /// Part of a union.
    public var implicit: CapnProto.VoidValue? {
      whichDiscriminant.rawValue == 0 ? .init() : nil
    }

    public func setImplicit() {
      _ = struct$.write(UInt16(0), atByte: 10)
    }

    /// The original ordinal number given to the field.  You probably should NOT use this; if you need
    /// a numeric identifier for a field, use its position within the field array for its scope.
    /// The ordinal is given here mainly just so that the original schema text can be reproduced given
    /// the compiled version -- i.e. so that `capnp compile -ocapnp` can do its job.
    ///
    /// Part of a union.
    public var explicit: UInt16? {
      whichDiscriminant.rawValue == 1 ? struct$.read(atByte: 12) : nil
    }

    public func setExplicit(_ newValue: UInt16) {
      if struct$.write(UInt16(1), atByte: 10) {
        _ = struct$.write(newValue, atByte: 12)
      }
    }
  }

  public var struct$: CapnProto.StructPointer

  public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

  public enum Which {
    public enum Discriminant: UInt16, CapnProto.EnumOrDiscriminant {
      public static let defaultValue: Discriminant = .slot
      public static let maxValue: Discriminant = .group

      case slot = 0
      case group = 1
    }

    case slot(Slot)
    case group(Group)
  }

  public var whichDiscriminant: CapnProto.EnumValue<Which.Discriminant> {
    struct$.readEnum(atByte: 8, defaultValue: .slot)
  }

  public func which() -> Which? {
    switch whichDiscriminant.rawValue {
    case 0: .slot(.init(struct$))
    case 1: .group(.init(struct$))
    default: nil
    }
  }

  public func name() throws(CapnProto.PointerError) -> CapnProto.Text {
    try struct$.readText(at: 0) ?? .init()
  }

  public func setName(_ text: Substring) -> CapnProto.Text? {
    struct$.writeText(text, at: 0)
  }

  /// Indicates where this member appeared in the code, relative to other members.
  /// Code ordering may have semantic relevance -- programmers tend to place related fields
  /// together.  So, using code ordering makes sense in human-readable formats where ordering is
  /// otherwise irrelevant, like JSON.  The values of codeOrder are tightly-packed, so the maximum
  /// value is count(members) - 1.  Fields that are members of a union are only ordered relative to
  /// the other members of that union, so the maximum value there is count(union.members).
  public var codeOrder: UInt16 {
    get { struct$.read(atByte: 0) }
    nonmutating set { _ = struct$.write(newValue, atByte: 0) }
  }

  public func annotations() throws(CapnProto.PointerError) -> CapnProto.List<Annotation> {
    try struct$.readList(at: 1) ?? .init()
  }

  public func initAnnotations(count: Int) -> CapnProto.List<Annotation>? {
    struct$.initList(at: 1, count: count)
  }

  /// If the field is in a union, this is the value which the union's discriminant should take when
  /// the field is active.  If the field is not in a union, this is 0xffff.
  public var discriminantValue: UInt16 {
    get { struct$.read(atByte: 2, defaultValue: 65535) }
    nonmutating set { _ = struct$.write(newValue, atByte: 2, defaultValue: 65535) }
  }

  /// A regular, non-group, non-fixed-list field.
  ///
  /// Part of a union.
  public var slot: Slot? { whichDiscriminant.rawValue == 0 ? .init(struct$) : nil }

  public func initSlot() -> Slot {
    _ = struct$.write(UInt16(0), atByte: 8)
    _ = struct$.write(UInt32(0), atByte: 4)
    _ = struct$.write(UInt64(0), atByte: 16)
    _ = struct$.write(UInt64(0), atByte: 24)
    _ = struct$.write(false, atBit: 128)
    return .init(struct$)
  }

  /// A group.
  ///
  /// Part of a union.
  public var group: Group? { whichDiscriminant.rawValue == 1 ? .init(struct$) : nil }

  public func initGroup() -> Group {
    _ = struct$.write(UInt16(1), atByte: 8)
    _ = struct$.write(UInt64(0), atByte: 16)
    return .init(struct$)
  }

  public var ordinal: Ordinal { .init(struct$) }
}

/// Schema for member of an enum.
public struct Enumerant: CapnProto.Struct {
  public static let id: UInt64 = 0x978a7cebdc549a4d
  public static let size: CapnProto.StructSize = .init(safeDataBytes: 8, pointers: 2)
  public static let firstFieldSize: CapnProto.ListElementSize? = .pointer

  public var struct$: CapnProto.StructPointer

  public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

  public func name() throws(CapnProto.PointerError) -> CapnProto.Text {
    try struct$.readText(at: 0) ?? .init()
  }

  public func setName(_ text: Substring) -> CapnProto.Text? {
    struct$.writeText(text, at: 0)
  }

  /// Specifies order in which the enumerants were declared in the code.
  /// Like Struct.Field.codeOrder.
  public var codeOrder: UInt16 {
    get { struct$.read(atByte: 0) }
    nonmutating set { _ = struct$.write(newValue, atByte: 0) }
  }

  public func annotations() throws(CapnProto.PointerError) -> CapnProto.List<Annotation> {
    try struct$.readList(at: 1) ?? .init()
  }

  public func initAnnotations(count: Int) -> CapnProto.List<Annotation>? {
    struct$.initList(at: 1, count: count)
  }
}

public struct Superclass: CapnProto.Struct {
  public static let id: UInt64 = 0xa9962a9ed0a4d7f8
  public static let size: CapnProto.StructSize = .init(safeDataBytes: 8, pointers: 1)
  public static let firstFieldSize: CapnProto.ListElementSize? = .eightBytes

  public var struct$: CapnProto.StructPointer

  public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

  public var id: UInt64 {
    get { struct$.read(atByte: 0) }
    nonmutating set { _ = struct$.write(newValue, atByte: 0) }
  }

  public func brand() throws(CapnProto.PointerError) -> Brand {
    try struct$.readStruct(at: 0) ?? .init()
  }

  public func initBrand() -> Brand? {
    struct$.initStruct(at: 0)
  }
}

/// Schema for method of an interface.
public struct Method: CapnProto.Struct {
  public static let id: UInt64 = 0x9500cce23b334d80
  public static let size: CapnProto.StructSize = .init(safeDataBytes: 24, pointers: 5)
  public static let firstFieldSize: CapnProto.ListElementSize? = .pointer

  public var struct$: CapnProto.StructPointer

  public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

  public func name() throws(CapnProto.PointerError) -> CapnProto.Text {
    try struct$.readText(at: 0) ?? .init()
  }

  public func setName(_ text: Substring) -> CapnProto.Text? {
    struct$.writeText(text, at: 0)
  }

  /// Specifies order in which the methods were declared in the code.
  /// Like Struct.Field.codeOrder.
  public var codeOrder: UInt16 {
    get { struct$.read(atByte: 0) }
    nonmutating set { _ = struct$.write(newValue, atByte: 0) }
  }

  /// ID of the parameter struct type.  If a named parameter list was specified in the method
  /// declaration (rather than a single struct parameter type) then a corresponding struct type is
  /// auto-generated.  Such an auto-generated type will not be listed in the interface's
  /// `nestedNodes` and its `scopeId` will be zero -- it is completely detached from the namespace.
  /// (Awkwardly, it does of course inherit generic parameters from the method's scope, which makes
  /// this a situation where you can't just climb the scope chain to find where a particular
  /// generic parameter was introduced. Making the `scopeId` zero was a mistake.)
  public var paramStructType: UInt64 {
    get { struct$.read(atByte: 8) }
    nonmutating set { _ = struct$.write(newValue, atByte: 8) }
  }

  /// ID of the return struct type; similar to `paramStructType`.
  public var resultStructType: UInt64 {
    get { struct$.read(atByte: 16) }
    nonmutating set { _ = struct$.write(newValue, atByte: 16) }
  }

  public func annotations() throws(CapnProto.PointerError) -> CapnProto.List<Annotation> {
    try struct$.readList(at: 1) ?? .init()
  }

  public func initAnnotations(count: Int) -> CapnProto.List<Annotation>? {
    struct$.initList(at: 1, count: count)
  }

  /// Brand of param struct type.
  public func paramBrand() throws(CapnProto.PointerError) -> Brand {
    try struct$.readStruct(at: 2) ?? .init()
  }

  public func initParamBrand() -> Brand? {
    struct$.initStruct(at: 2)
  }

  /// Brand of result struct type.
  public func resultBrand() throws(CapnProto.PointerError) -> Brand {
    try struct$.readStruct(at: 3) ?? .init()
  }

  public func initResultBrand() -> Brand? {
    struct$.initStruct(at: 3)
  }

  /// The parameters listed in [] (typically, type / generic parameters), whose bindings are intended
  /// to be inferred rather than specified explicitly, although not all languages support this.
  public func implicitParameters() throws(CapnProto.PointerError) -> CapnProto.List<Node.Parameter> {
    try struct$.readList(at: 4) ?? .init()
  }

  public func initImplicitParameters(count: Int) -> CapnProto.List<Node.Parameter>? {
    struct$.initList(at: 4, count: count)
  }
}

/// Represents a type expression.
public struct `Type`: CapnProto.Struct {
  public static let id: UInt64 = 0xd07378ede1f9cc60
  public static let size: CapnProto.StructSize = .init(safeDataBytes: 24, pointers: 1)
  public static let firstFieldSize: CapnProto.ListElementSize? = .twoBytes

  /// Generated for group `list`.
  public struct List: CapnProto.Struct {
    public static let id: UInt64 = 0x87e739250a60ea97
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 24, pointers: 1)
    public static let firstFieldSize: CapnProto.ListElementSize? = .pointer

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    public func elementType() throws(CapnProto.PointerError) -> `Type` {
      try struct$.readStruct(at: 0) ?? .init()
    }

    public func initElementType() -> `Type`? {
      struct$.initStruct(at: 0)
    }
  }

  /// Generated for group `enum`.
  public struct Enum: CapnProto.Struct {
    public static let id: UInt64 = 0x9e0e78711a7f87a9
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 24, pointers: 1)
    public static let firstFieldSize: CapnProto.ListElementSize? = .eightBytes

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    public var typeId: UInt64 {
      get { struct$.read(atByte: 8) }
      nonmutating set { _ = struct$.write(newValue, atByte: 8) }
    }

    public func brand() throws(CapnProto.PointerError) -> Brand {
      try struct$.readStruct(at: 0) ?? .init()
    }

    public func initBrand() -> Brand? {
      struct$.initStruct(at: 0)
    }
  }

  /// Generated for group `struct`.
  public struct Struct: CapnProto.Struct {
    public static let id: UInt64 = 0xac3a6f60ef4cc6d3
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 24, pointers: 1)
    public static let firstFieldSize: CapnProto.ListElementSize? = .eightBytes

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    public var typeId: UInt64 {
      get { struct$.read(atByte: 8) }
      nonmutating set { _ = struct$.write(newValue, atByte: 8) }
    }

    public func brand() throws(CapnProto.PointerError) -> Brand {
      try struct$.readStruct(at: 0) ?? .init()
    }

    public func initBrand() -> Brand? {
      struct$.initStruct(at: 0)
    }
  }

  /// Generated for group `interface`.
  public struct Interface: CapnProto.Struct {
    public static let id: UInt64 = 0xed8bca69f7fb0cbf
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 24, pointers: 1)
    public static let firstFieldSize: CapnProto.ListElementSize? = .eightBytes

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    public var typeId: UInt64 {
      get { struct$.read(atByte: 8) }
      nonmutating set { _ = struct$.write(newValue, atByte: 8) }
    }

    public func brand() throws(CapnProto.PointerError) -> Brand {
      try struct$.readStruct(at: 0) ?? .init()
    }

    public func initBrand() -> Brand? {
      struct$.initStruct(at: 0)
    }
  }

  /// Generated for group `anyPointer`.
  public struct AnyPointer: CapnProto.Struct {
    public static let id: UInt64 = 0xc2573fe8a23e49f1
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 24, pointers: 1)
    public static let firstFieldSize: CapnProto.ListElementSize? = nil

    /// Generated for group `unconstrained`.
    public struct Unconstrained: CapnProto.Struct {
      public static let id: UInt64 = 0x8e3b5f79fe593656
      public static let size: CapnProto.StructSize = .init(safeDataBytes: 24, pointers: 1)
      public static let firstFieldSize: CapnProto.ListElementSize? = nil

      public var struct$: CapnProto.StructPointer

      public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

      public enum Which {
        public enum Discriminant: UInt16, CapnProto.EnumOrDiscriminant {
          public static let defaultValue: Discriminant = .anyKind
          public static let maxValue: Discriminant = .capability

          case anyKind = 0
          case `struct` = 1
          case list = 2
          case capability = 3
        }

        case anyKind
        case `struct`
        case list
        case capability
      }

      public var whichDiscriminant: CapnProto.EnumValue<Which.Discriminant> {
        struct$.readEnum(atByte: 10, defaultValue: .anyKind)
      }

      public func which() -> Which? {
        switch whichDiscriminant.rawValue {
        case 0: .anyKind
        case 1: .struct
        case 2: .list
        case 3: .capability
        default: nil
        }
      }

      /// truly AnyPointer
      ///
      /// Part of a union.
      public var anyKind: CapnProto.VoidValue? {
        whichDiscriminant.rawValue == 0 ? .init() : nil
      }

      public func setAnyKind() {
        _ = struct$.write(UInt16(0), atByte: 10)
      }

      /// StructPointer
      ///
      /// Part of a union.
      public var `struct`: CapnProto.VoidValue? {
        whichDiscriminant.rawValue == 1 ? .init() : nil
      }

      public func setStruct() {
        _ = struct$.write(UInt16(1), atByte: 10)
      }

      /// ListPointer
      ///
      /// Part of a union.
      public var list: CapnProto.VoidValue? {
        whichDiscriminant.rawValue == 2 ? .init() : nil
      }

      public func setList() {
        _ = struct$.write(UInt16(2), atByte: 10)
      }

      /// Capability
      ///
      /// Part of a union.
      public var capability: CapnProto.VoidValue? {
        whichDiscriminant.rawValue == 3 ? .init() : nil
      }

      public func setCapability() {
        _ = struct$.write(UInt16(3), atByte: 10)
      }
    }

    /// Generated for group `parameter`.
    public struct Parameter: CapnProto.Struct {
      public static let id: UInt64 = 0x9dd1f724f4614a85
      public static let size: CapnProto.StructSize = .init(safeDataBytes: 24, pointers: 1)
      public static let firstFieldSize: CapnProto.ListElementSize? = .eightBytes

      public var struct$: CapnProto.StructPointer

      public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

      /// ID of the generic type whose parameter we're referencing. This should be a parent of the
      /// current scope.
      public var scopeId: UInt64 {
        get { struct$.read(atByte: 16) }
        nonmutating set { _ = struct$.write(newValue, atByte: 16) }
      }

      /// Index of the parameter within the generic type's parameter list.
      public var parameterIndex: UInt16 {
        get { struct$.read(atByte: 10) }
        nonmutating set { _ = struct$.write(newValue, atByte: 10) }
      }
    }

    /// Generated for group `implicitMethodParameter`.
    public struct ImplicitMethodParameter: CapnProto.Struct {
      public static let id: UInt64 = 0xbaefc9120c56e274
      public static let size: CapnProto.StructSize = .init(safeDataBytes: 24, pointers: 1)
      public static let firstFieldSize: CapnProto.ListElementSize? = .twoBytes

      public var struct$: CapnProto.StructPointer

      public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

      public var parameterIndex: UInt16 {
        get { struct$.read(atByte: 10) }
        nonmutating set { _ = struct$.write(newValue, atByte: 10) }
      }
    }

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    public enum Which {
      public enum Discriminant: UInt16, CapnProto.EnumOrDiscriminant {
        public static let defaultValue: Discriminant = .unconstrained
        public static let maxValue: Discriminant = .implicitMethodParameter

        case unconstrained = 0
        case parameter = 1
        case implicitMethodParameter = 2
      }

      case unconstrained(Unconstrained)
      case parameter(Parameter)
      case implicitMethodParameter(ImplicitMethodParameter)
    }

    public var whichDiscriminant: CapnProto.EnumValue<Which.Discriminant> {
      struct$.readEnum(atByte: 8, defaultValue: .unconstrained)
    }

    public func which() -> Which? {
      switch whichDiscriminant.rawValue {
      case 0: .unconstrained(.init(struct$))
      case 1: .parameter(.init(struct$))
      case 2: .implicitMethodParameter(.init(struct$))
      default: nil
      }
    }

    /// A regular AnyPointer.
    ///
    /// The name "unconstrained" means as opposed to constraining it to match a type parameter.
    /// In retrospect this name is probably a poor choice given that it may still be constrained
    /// to be a struct, list, or capability.
    ///
    /// Part of a union.
    public var unconstrained: Unconstrained? { whichDiscriminant.rawValue == 0 ? .init(struct$) : nil }

    public func initUnconstrained() -> Unconstrained {
      _ = struct$.write(UInt16(0), atByte: 8)
      return .init(struct$)
    }

    /// This is actually a reference to a type parameter defined within this scope.
    ///
    /// Part of a union.
    public var parameter: Parameter? { whichDiscriminant.rawValue == 1 ? .init(struct$) : nil }

    public func initParameter() -> Parameter {
      _ = struct$.write(UInt16(1), atByte: 8)
      _ = struct$.write(UInt64(0), atByte: 16)
      _ = struct$.write(UInt16(0), atByte: 10)
      return .init(struct$)
    }

    /// This is actually a reference to an implicit (generic) parameter of a method. The only
    /// legal context for this type to appear is inside Method.paramBrand or Method.resultBrand.
    ///
    /// Part of a union.
    public var implicitMethodParameter: ImplicitMethodParameter? { whichDiscriminant.rawValue == 2 ? .init(struct$) : nil }

    public func initImplicitMethodParameter() -> ImplicitMethodParameter {
      _ = struct$.write(UInt16(2), atByte: 8)
      _ = struct$.write(UInt16(0), atByte: 10)
      return .init(struct$)
    }
  }

  public var struct$: CapnProto.StructPointer

  public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

  public enum Which {
    public enum Discriminant: UInt16, CapnProto.EnumOrDiscriminant {
      public static let defaultValue: Discriminant = .void
      public static let maxValue: Discriminant = .anyPointer

      case void = 0
      case bool = 1
      case int8 = 2
      case int16 = 3
      case int32 = 4
      case int64 = 5
      case uint8 = 6
      case uint16 = 7
      case uint32 = 8
      case uint64 = 9
      case float32 = 10
      case float64 = 11
      case text = 12
      case data = 13
      case list = 14
      case `enum` = 15
      case `struct` = 16
      case interface = 17
      case anyPointer = 18
    }

    case void
    case bool
    case int8
    case int16
    case int32
    case int64
    case uint8
    case uint16
    case uint32
    case uint64
    case float32
    case float64
    case text
    case data
    case list(List)
    case `enum`(Enum)
    case `struct`(Struct)
    case interface(Interface)
    case anyPointer(AnyPointer)
  }

  public var whichDiscriminant: CapnProto.EnumValue<Which.Discriminant> {
    struct$.readEnum(atByte: 0, defaultValue: .void)
  }

  public func which() -> Which? {
    switch whichDiscriminant.rawValue {
    case 0: .void
    case 1: .bool
    case 2: .int8
    case 3: .int16
    case 4: .int32
    case 5: .int64
    case 6: .uint8
    case 7: .uint16
    case 8: .uint32
    case 9: .uint64
    case 10: .float32
    case 11: .float64
    case 12: .text
    case 13: .data
    case 14: .list(.init(struct$))
    case 15: .enum(.init(struct$))
    case 16: .struct(.init(struct$))
    case 17: .interface(.init(struct$))
    case 18: .anyPointer(.init(struct$))
    default: nil
    }
  }

  /// Part of a union.
  public var void: CapnProto.VoidValue? {
    whichDiscriminant.rawValue == 0 ? .init() : nil
  }

  public func setVoid() {
    _ = struct$.write(UInt16(0), atByte: 0)
  }

  /// Part of a union.
  public var bool: CapnProto.VoidValue? {
    whichDiscriminant.rawValue == 1 ? .init() : nil
  }

  public func setBool() {
    _ = struct$.write(UInt16(1), atByte: 0)
  }

  /// Part of a union.
  public var int8: CapnProto.VoidValue? {
    whichDiscriminant.rawValue == 2 ? .init() : nil
  }

  public func setInt8() {
    _ = struct$.write(UInt16(2), atByte: 0)
  }

  /// Part of a union.
  public var int16: CapnProto.VoidValue? {
    whichDiscriminant.rawValue == 3 ? .init() : nil
  }

  public func setInt16() {
    _ = struct$.write(UInt16(3), atByte: 0)
  }

  /// Part of a union.
  public var int32: CapnProto.VoidValue? {
    whichDiscriminant.rawValue == 4 ? .init() : nil
  }

  public func setInt32() {
    _ = struct$.write(UInt16(4), atByte: 0)
  }

  /// Part of a union.
  public var int64: CapnProto.VoidValue? {
    whichDiscriminant.rawValue == 5 ? .init() : nil
  }

  public func setInt64() {
    _ = struct$.write(UInt16(5), atByte: 0)
  }

  /// Part of a union.
  public var uint8: CapnProto.VoidValue? {
    whichDiscriminant.rawValue == 6 ? .init() : nil
  }

  public func setUint8() {
    _ = struct$.write(UInt16(6), atByte: 0)
  }

  /// Part of a union.
  public var uint16: CapnProto.VoidValue? {
    whichDiscriminant.rawValue == 7 ? .init() : nil
  }

  public func setUint16() {
    _ = struct$.write(UInt16(7), atByte: 0)
  }

  /// Part of a union.
  public var uint32: CapnProto.VoidValue? {
    whichDiscriminant.rawValue == 8 ? .init() : nil
  }

  public func setUint32() {
    _ = struct$.write(UInt16(8), atByte: 0)
  }

  /// Part of a union.
  public var uint64: CapnProto.VoidValue? {
    whichDiscriminant.rawValue == 9 ? .init() : nil
  }

  public func setUint64() {
    _ = struct$.write(UInt16(9), atByte: 0)
  }

  /// Part of a union.
  public var float32: CapnProto.VoidValue? {
    whichDiscriminant.rawValue == 10 ? .init() : nil
  }

  public func setFloat32() {
    _ = struct$.write(UInt16(10), atByte: 0)
  }

  /// Part of a union.
  public var float64: CapnProto.VoidValue? {
    whichDiscriminant.rawValue == 11 ? .init() : nil
  }

  public func setFloat64() {
    _ = struct$.write(UInt16(11), atByte: 0)
  }

  /// Part of a union.
  public var text: CapnProto.VoidValue? {
    whichDiscriminant.rawValue == 12 ? .init() : nil
  }

  public func setText() {
    _ = struct$.write(UInt16(12), atByte: 0)
  }

  /// Part of a union.
  public var data: CapnProto.VoidValue? {
    whichDiscriminant.rawValue == 13 ? .init() : nil
  }

  public func setData() {
    _ = struct$.write(UInt16(13), atByte: 0)
  }

  /// Part of a union.
  public var list: List? { whichDiscriminant.rawValue == 14 ? .init(struct$) : nil }

  public func initList() -> List {
    _ = struct$.write(UInt16(14), atByte: 0)
    _ = struct$.write(UInt64(0), atByte: 0)
    return .init(struct$)
  }

  /// Part of a union.
  public var `enum`: Enum? { whichDiscriminant.rawValue == 15 ? .init(struct$) : nil }

  public func initEnum() -> Enum {
    _ = struct$.write(UInt16(15), atByte: 0)
    _ = struct$.write(UInt64(0), atByte: 8)
    _ = struct$.write(UInt64(0), atByte: 0)
    return .init(struct$)
  }

  /// Part of a union.
  public var `struct`: Struct? { whichDiscriminant.rawValue == 16 ? .init(struct$) : nil }

  public func initStruct() -> Struct {
    _ = struct$.write(UInt16(16), atByte: 0)
    _ = struct$.write(UInt64(0), atByte: 8)
    _ = struct$.write(UInt64(0), atByte: 0)
    return .init(struct$)
  }

  /// Part of a union.
  public var interface: Interface? { whichDiscriminant.rawValue == 17 ? .init(struct$) : nil }

  public func initInterface() -> Interface {
    _ = struct$.write(UInt16(17), atByte: 0)
    _ = struct$.write(UInt64(0), atByte: 8)
    _ = struct$.write(UInt64(0), atByte: 0)
    return .init(struct$)
  }

  /// Part of a union.
  public var anyPointer: AnyPointer? { whichDiscriminant.rawValue == 18 ? .init(struct$) : nil }

  public func initAnyPointer() -> AnyPointer {
    _ = struct$.write(UInt16(18), atByte: 0)
    _ = struct$.write(UInt64(0), atByte: 16)
    _ = struct$.write(UInt16(0), atByte: 10)
    _ = struct$.write(UInt16(0), atByte: 10)
    return .init(struct$)
  }
}

/// Specifies bindings for parameters of generics. Since these bindings turn a generic into a
/// non-generic, we call it the "brand".
public struct Brand: CapnProto.Struct {
  public static let id: UInt64 = 0x903455f06065422b
  public static let size: CapnProto.StructSize = .init(safeDataBytes: 0, pointers: 1)
  public static let firstFieldSize: CapnProto.ListElementSize? = .pointer

  public struct Scope: CapnProto.Struct {
    public static let id: UInt64 = 0xabd73485a9636bc9
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 16, pointers: 1)
    public static let firstFieldSize: CapnProto.ListElementSize? = .eightBytes

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    public enum Which {
      public enum Discriminant: UInt16, CapnProto.EnumOrDiscriminant {
        public static let defaultValue: Discriminant = .bind
        public static let maxValue: Discriminant = .inherit

        case bind = 0
        case inherit = 1
      }

      case bind(CapnProto.List<Binding>)
      case inherit
    }

    public var whichDiscriminant: CapnProto.EnumValue<Which.Discriminant> {
      struct$.readEnum(atByte: 8, defaultValue: .bind)
    }

    public func which() throws(CapnProto.PointerError) -> Which? {
      switch whichDiscriminant.rawValue {
      case 0: .bind(try struct$.readList(at: 0) ?? .init())
      case 1: .inherit
      default: nil
      }
    }

    /// ID of the scope to which these params apply.
    public var scopeId: UInt64 {
      get { struct$.read(atByte: 0) }
      nonmutating set { _ = struct$.write(newValue, atByte: 0) }
    }

    /// List of parameter bindings.
    ///
    /// Part of a union.
    public func bind() throws(CapnProto.PointerError) -> CapnProto.List<Binding>? {
      whichDiscriminant.rawValue == 0 ? try struct$.readList(at: 0) ?? .init() : nil
    }

    public func initBind(count: Int) -> CapnProto.List<Binding>? {
      struct$.write(UInt16(0), atByte: 8) ? struct$.initList(at: 0, count: count) : nil
    }

    /// The place where the Brand appears is within this scope or a sub-scope, and bindings
    /// for this scope are deferred to later Brand applications. This is equivalent to a
    /// pass-through binding list, where each of this scope's parameters is bound to itself.
    /// For example:
    ///
    ///   struct Outer(T) {
    ///     struct Inner {
    ///       value @0 :T;
    ///     }
    ///     innerInherit @0 :Inner;            # Outer Brand.Scope is `inherit`.
    ///     innerBindSelf @1 :Outer(T).Inner;  # Outer Brand.Scope explicitly binds T to T.
    ///   }
    ///
    /// The innerInherit and innerBindSelf fields have equivalent types, but different Brand
    /// styles.
    ///
    /// Part of a union.
    public var inherit: CapnProto.VoidValue? {
      whichDiscriminant.rawValue == 1 ? .init() : nil
    }

    public func setInherit() {
      _ = struct$.write(UInt16(1), atByte: 8)
    }
  }

  public struct Binding: CapnProto.Struct {
    public static let id: UInt64 = 0xc863cd16969ee7fc
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 8, pointers: 1)
    public static let firstFieldSize: CapnProto.ListElementSize? = .twoBytes

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    public enum Which {
      public enum Discriminant: UInt16, CapnProto.EnumOrDiscriminant {
        public static let defaultValue: Discriminant = .unbound
        public static let maxValue: Discriminant = .type

        case unbound = 0
        case type = 1
      }

      case unbound
      case type(`Type`)
    }

    public var whichDiscriminant: CapnProto.EnumValue<Which.Discriminant> {
      struct$.readEnum(atByte: 0, defaultValue: .unbound)
    }

    public func which() throws(CapnProto.PointerError) -> Which? {
      switch whichDiscriminant.rawValue {
      case 0: .unbound
      case 1: .type(try struct$.readStruct(at: 0) ?? .init())
      default: nil
      }
    }

    /// Part of a union.
    public var unbound: CapnProto.VoidValue? {
      whichDiscriminant.rawValue == 0 ? .init() : nil
    }

    public func setUnbound() {
      _ = struct$.write(UInt16(0), atByte: 0)
    }

    /// Part of a union.
    public func type() throws(CapnProto.PointerError) -> `Type`? {
      whichDiscriminant.rawValue == 1 ? try struct$.readStruct(at: 0) ?? .init() : nil
    }

    public func initType() -> `Type`? {
      struct$.write(UInt16(1), atByte: 0) ? struct$.initStruct(at: 0) : nil
    }
  }

  public var struct$: CapnProto.StructPointer

  public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

  /// For each of the target type and each of its parent scopes, a parameterization may be included
  /// in this list. If no parameterization is included for a particular relevant scope, then either
  /// that scope has no parameters or all parameters should be considered to be `AnyPointer`.
  public func scopes() throws(CapnProto.PointerError) -> CapnProto.List<Scope> {
    try struct$.readList(at: 0) ?? .init()
  }

  public func initScopes(count: Int) -> CapnProto.List<Scope>? {
    struct$.initList(at: 0, count: count)
  }
}

/// Represents a value, e.g. a field default value, constant value, or annotation value.
public struct Value: CapnProto.Struct {
  public static let id: UInt64 = 0xce23dcd2d7b00c9b
  public static let size: CapnProto.StructSize = .init(safeDataBytes: 16, pointers: 1)
  public static let firstFieldSize: CapnProto.ListElementSize? = .twoBytes

  public var struct$: CapnProto.StructPointer

  public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

  public enum Which {
    public enum Discriminant: UInt16, CapnProto.EnumOrDiscriminant {
      public static let defaultValue: Discriminant = .void
      public static let maxValue: Discriminant = .anyPointer

      case void = 0
      case bool = 1
      case int8 = 2
      case int16 = 3
      case int32 = 4
      case int64 = 5
      case uint8 = 6
      case uint16 = 7
      case uint32 = 8
      case uint64 = 9
      case float32 = 10
      case float64 = 11
      case text = 12
      case data = 13
      case list = 14
      case `enum` = 15
      case `struct` = 16
      case interface = 17
      case anyPointer = 18
    }

    case void
    case bool(Bool)
    case int8(Int8)
    case int16(Int16)
    case int32(Int32)
    case int64(Int64)
    case uint8(UInt8)
    case uint16(UInt16)
    case uint32(UInt32)
    case uint64(UInt64)
    case float32(Float32)
    case float64(Float64)
    case text(CapnProto.Text)
    case data(CapnProto.List<UInt8>)
    case list(CapnProto.AnyPointer?)
    case `enum`(UInt16)
    case `struct`(CapnProto.AnyPointer?)
    case interface
    case anyPointer(CapnProto.AnyPointer?)
  }

  public var whichDiscriminant: CapnProto.EnumValue<Which.Discriminant> {
    struct$.readEnum(atByte: 0, defaultValue: .void)
  }

  public func which() throws(CapnProto.PointerError) -> Which? {
    switch whichDiscriminant.rawValue {
    case 0: .void
    case 1: .bool(struct$.read(atBit: 16))
    case 2: .int8(struct$.read(atByte: 2))
    case 3: .int16(struct$.read(atByte: 2))
    case 4: .int32(struct$.read(atByte: 4))
    case 5: .int64(struct$.read(atByte: 8))
    case 6: .uint8(struct$.read(atByte: 2))
    case 7: .uint16(struct$.read(atByte: 2))
    case 8: .uint32(struct$.read(atByte: 4))
    case 9: .uint64(struct$.read(atByte: 8))
    case 10: .float32(struct$.read(atByte: 4))
    case 11: .float64(struct$.read(atByte: 8))
    case 12: .text(try struct$.readText(at: 0) ?? .init())
    case 13: .data(try struct$.readList(at: 0) ?? .init())
    case 14: .list(struct$.readAnyPointer(at: 0))
    case 15: .enum(struct$.read(atByte: 2))
    case 16: .struct(struct$.readAnyPointer(at: 0))
    case 17: .interface
    case 18: .anyPointer(struct$.readAnyPointer(at: 0))
    default: nil
    }
  }

  /// Part of a union.
  public var void: CapnProto.VoidValue? {
    whichDiscriminant.rawValue == 0 ? .init() : nil
  }

  public func setVoid() {
    _ = struct$.write(UInt16(0), atByte: 0)
  }

  /// Part of a union.
  public var bool: Bool? {
    whichDiscriminant.rawValue == 1 ? struct$.read(atBit: 16) : nil
  }

  public func setBool(_ newValue: Bool) {
    if struct$.write(UInt16(1), atByte: 0) {
      _ = struct$.write(newValue, atBit: 16)
    }
  }

  /// Part of a union.
  public var int8: Int8? {
    whichDiscriminant.rawValue == 2 ? struct$.read(atByte: 2) : nil
  }

  public func setInt8(_ newValue: Int8) {
    if struct$.write(UInt16(2), atByte: 0) {
      _ = struct$.write(newValue, atByte: 2)
    }
  }

  /// Part of a union.
  public var int16: Int16? {
    whichDiscriminant.rawValue == 3 ? struct$.read(atByte: 2) : nil
  }

  public func setInt16(_ newValue: Int16) {
    if struct$.write(UInt16(3), atByte: 0) {
      _ = struct$.write(newValue, atByte: 2)
    }
  }

  /// Part of a union.
  public var int32: Int32? {
    whichDiscriminant.rawValue == 4 ? struct$.read(atByte: 4) : nil
  }

  public func setInt32(_ newValue: Int32) {
    if struct$.write(UInt16(4), atByte: 0) {
      _ = struct$.write(newValue, atByte: 4)
    }
  }

  /// Part of a union.
  public var int64: Int64? {
    whichDiscriminant.rawValue == 5 ? struct$.read(atByte: 8) : nil
  }

  public func setInt64(_ newValue: Int64) {
    if struct$.write(UInt16(5), atByte: 0) {
      _ = struct$.write(newValue, atByte: 8)
    }
  }

  /// Part of a union.
  public var uint8: UInt8? {
    whichDiscriminant.rawValue == 6 ? struct$.read(atByte: 2) : nil
  }

  public func setUint8(_ newValue: UInt8) {
    if struct$.write(UInt16(6), atByte: 0) {
      _ = struct$.write(newValue, atByte: 2)
    }
  }

  /// Part of a union.
  public var uint16: UInt16? {
    whichDiscriminant.rawValue == 7 ? struct$.read(atByte: 2) : nil
  }

  public func setUint16(_ newValue: UInt16) {
    if struct$.write(UInt16(7), atByte: 0) {
      _ = struct$.write(newValue, atByte: 2)
    }
  }

  /// Part of a union.
  public var uint32: UInt32? {
    whichDiscriminant.rawValue == 8 ? struct$.read(atByte: 4) : nil
  }

  public func setUint32(_ newValue: UInt32) {
    if struct$.write(UInt16(8), atByte: 0) {
      _ = struct$.write(newValue, atByte: 4)
    }
  }

  /// Part of a union.
  public var uint64: UInt64? {
    whichDiscriminant.rawValue == 9 ? struct$.read(atByte: 8) : nil
  }

  public func setUint64(_ newValue: UInt64) {
    if struct$.write(UInt16(9), atByte: 0) {
      _ = struct$.write(newValue, atByte: 8)
    }
  }

  /// Part of a union.
  public var float32: Float32? {
    whichDiscriminant.rawValue == 10 ? struct$.read(atByte: 4) : nil
  }

  public func setFloat32(_ newValue: Float32) {
    if struct$.write(UInt16(10), atByte: 0) {
      _ = struct$.write(newValue, atByte: 4)
    }
  }

  /// Part of a union.
  public var float64: Float64? {
    whichDiscriminant.rawValue == 11 ? struct$.read(atByte: 8) : nil
  }

  public func setFloat64(_ newValue: Float64) {
    if struct$.write(UInt16(11), atByte: 0) {
      _ = struct$.write(newValue, atByte: 8)
    }
  }

  /// Part of a union.
  public func text() throws(CapnProto.PointerError) -> CapnProto.Text? {
    whichDiscriminant.rawValue == 12 ? try struct$.readText(at: 0) ?? .init() : nil
  }

  public func setText(_ text: Substring) -> CapnProto.Text? {
    struct$.write(UInt16(12), atByte: 0) ? struct$.writeText(text, at: 0) : nil
  }

  /// Part of a union.
  public func data() throws(CapnProto.PointerError) -> CapnProto.List<UInt8>? {
    whichDiscriminant.rawValue == 13 ? try struct$.readList(at: 0) ?? .init() : nil
  }

  public func initData(count: Int) -> CapnProto.List<UInt8>? {
    struct$.write(UInt16(13), atByte: 0) ? struct$.initList(at: 0, count: count) : nil
  }

  /// Part of a union.
  public var list: CapnProto.AnyPointer? {
    whichDiscriminant.rawValue == 14 ? struct$.readAnyPointer(at: 0) : nil
  }

  /// Part of a union.
  public var `enum`: UInt16? {
    whichDiscriminant.rawValue == 15 ? struct$.read(atByte: 2) : nil
  }

  public func setEnum(_ newValue: UInt16) {
    if struct$.write(UInt16(15), atByte: 0) {
      _ = struct$.write(newValue, atByte: 2)
    }
  }

  /// Part of a union.
  public var `struct`: CapnProto.AnyPointer? {
    whichDiscriminant.rawValue == 16 ? struct$.readAnyPointer(at: 0) : nil
  }

  /// The only interface value that can be represented statically is "null", whose methods always
  /// throw exceptions.
  ///
  /// Part of a union.
  public var interface: CapnProto.VoidValue? {
    whichDiscriminant.rawValue == 17 ? .init() : nil
  }

  public func setInterface() {
    _ = struct$.write(UInt16(17), atByte: 0)
  }

  /// Part of a union.
  public var anyPointer: CapnProto.AnyPointer? {
    whichDiscriminant.rawValue == 18 ? struct$.readAnyPointer(at: 0) : nil
  }
}

/// Describes an annotation applied to a declaration.  Note AnnotationNode describes the
/// annotation's declaration, while this describes a use of the annotation.
public struct Annotation: CapnProto.Struct {
  public static let id: UInt64 = 0xf1c8950dab257542
  public static let size: CapnProto.StructSize = .init(safeDataBytes: 8, pointers: 2)
  public static let firstFieldSize: CapnProto.ListElementSize? = .eightBytes

  public var struct$: CapnProto.StructPointer

  public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

  /// ID of the annotation node.
  public var id: UInt64 {
    get { struct$.read(atByte: 0) }
    nonmutating set { _ = struct$.write(newValue, atByte: 0) }
  }

  public func value() throws(CapnProto.PointerError) -> Value {
    try struct$.readStruct(at: 0) ?? .init()
  }

  public func initValue() -> Value? {
    struct$.initStruct(at: 0)
  }

  /// Brand of the annotation.
  ///
  /// Note that the annotation itself is not allowed to be parameterized, but its scope might be.
  public func brand() throws(CapnProto.PointerError) -> Brand {
    try struct$.readStruct(at: 1) ?? .init()
  }

  public func initBrand() -> Brand? {
    struct$.initStruct(at: 1)
  }
}

/// Possible element sizes for encoded lists.  These correspond exactly to the possible values of
/// the 3-bit element size component of a list pointer.
public enum ElementSize: UInt16, CapnProto.Enum {
  public static let id: UInt64 = 0xd1958f7dba521926
  public static let defaultValue: Self = .empty
  public static let maxValue: Self = .inlineComposite

  /// aka "void", but that's a keyword.
  case empty = 0
  case bit = 1
  case byte = 2
  case twoBytes = 3
  case fourBytes = 4
  case eightBytes = 5
  case pointer = 6
  case inlineComposite = 7
}

public struct CapnpVersion: CapnProto.Struct {
  public static let id: UInt64 = 0xd85d305b7d839963
  public static let size: CapnProto.StructSize = .init(safeDataBytes: 8, pointers: 0)
  public static let firstFieldSize: CapnProto.ListElementSize? = .twoBytes

  public var struct$: CapnProto.StructPointer

  public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

  public var major: UInt16 {
    get { struct$.read(atByte: 0) }
    nonmutating set { _ = struct$.write(newValue, atByte: 0) }
  }

  public var minor: UInt8 {
    get { struct$.read(atByte: 2) }
    nonmutating set { _ = struct$.write(newValue, atByte: 2) }
  }

  public var micro: UInt8 {
    get { struct$.read(atByte: 3) }
    nonmutating set { _ = struct$.write(newValue, atByte: 3) }
  }
}

public struct CodeGeneratorRequest: CapnProto.Struct {
  public static let id: UInt64 = 0xbfc546f6210ad7ce
  public static let size: CapnProto.StructSize = .init(safeDataBytes: 0, pointers: 4)
  public static let firstFieldSize: CapnProto.ListElementSize? = .pointer

  public struct RequestedFile: CapnProto.Struct {
    public static let id: UInt64 = 0xcfea0eb02e810062
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 8, pointers: 3)
    public static let firstFieldSize: CapnProto.ListElementSize? = .eightBytes

    public struct Import: CapnProto.Struct {
      public static let id: UInt64 = 0xae504193122357e5
      public static let size: CapnProto.StructSize = .init(safeDataBytes: 8, pointers: 1)
      public static let firstFieldSize: CapnProto.ListElementSize? = .eightBytes

      public var struct$: CapnProto.StructPointer

      public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

      /// ID of the imported file.
      public var id: UInt64 {
        get { struct$.read(atByte: 0) }
        nonmutating set { _ = struct$.write(newValue, atByte: 0) }
      }

      /// Name which *this* file used to refer to the foreign file.  This may be a relative name.
      /// This information is provided because it might be useful for code generation, e.g. to
      /// generate #include directives in C++.  We don't put this in Node.file because this
      /// information is only meaningful at compile time anyway.
      ///
      /// (On Zooko's triangle, this is the import's petname according to the importing file.)
      public func name() throws(CapnProto.PointerError) -> CapnProto.Text {
        try struct$.readText(at: 0) ?? .init()
      }

      public func setName(_ text: Substring) -> CapnProto.Text? {
        struct$.writeText(text, at: 0)
      }
    }

    public struct FileSourceInfo: CapnProto.Struct {
      public static let id: UInt64 = 0xf8ea2bf176925da0
      public static let size: CapnProto.StructSize = .init(safeDataBytes: 0, pointers: 1)
      public static let firstFieldSize: CapnProto.ListElementSize? = .pointer

      public struct Identifier: CapnProto.Struct {
        public static let id: UInt64 = 0xdda719892e0499bb
        public static let size: CapnProto.StructSize = .init(safeDataBytes: 24, pointers: 0)
        public static let firstFieldSize: CapnProto.ListElementSize? = .fourBytes

        /// Generated for group `member`.
        public struct Member: CapnProto.Struct {
          public static let id: UInt64 = 0xfc69d5e1d630a151
          public static let size: CapnProto.StructSize = .init(safeDataBytes: 24, pointers: 0)
          public static let firstFieldSize: CapnProto.ListElementSize? = .eightBytes

          public var struct$: CapnProto.StructPointer

          public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

          public var parentTypeId: UInt64 {
            get { struct$.read(atByte: 8) }
            nonmutating set { _ = struct$.write(newValue, atByte: 8) }
          }

          public var ordinal: UInt16 {
            get { struct$.read(atByte: 18) }
            nonmutating set { _ = struct$.write(newValue, atByte: 18) }
          }
        }

        public var struct$: CapnProto.StructPointer

        public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

        public enum Which {
          public enum Discriminant: UInt16, CapnProto.EnumOrDiscriminant {
            public static let defaultValue: Discriminant = .typeId
            public static let maxValue: Discriminant = .member

            case typeId = 0
            case member = 1
          }

          case typeId(UInt64)
          case member(Member)
        }

        public var whichDiscriminant: CapnProto.EnumValue<Which.Discriminant> {
          struct$.readEnum(atByte: 16, defaultValue: .typeId)
        }

        public func which() -> Which? {
          switch whichDiscriminant.rawValue {
          case 0: .typeId(struct$.read(atByte: 8))
          case 1: .member(.init(struct$))
          default: nil
          }
        }

        public var startByte: UInt32 {
          get { struct$.read(atByte: 0) }
          nonmutating set { _ = struct$.write(newValue, atByte: 0) }
        }

        public var endByte: UInt32 {
          get { struct$.read(atByte: 4) }
          nonmutating set { _ = struct$.write(newValue, atByte: 4) }
        }

        /// Identifier refers to a type. This is the type ID.
        ///
        /// Part of a union.
        public var typeId: UInt64? {
          whichDiscriminant.rawValue == 0 ? struct$.read(atByte: 8) : nil
        }

        public func setTypeId(_ newValue: UInt64) {
          if struct$.write(UInt16(0), atByte: 16) {
            _ = struct$.write(newValue, atByte: 8)
          }
        }

        /// Identifier refers to a member of a type.
        ///
        /// Part of a union.
        public var member: Member? { whichDiscriminant.rawValue == 1 ? .init(struct$) : nil }

        public func initMember() -> Member {
          _ = struct$.write(UInt16(1), atByte: 16)
          _ = struct$.write(UInt64(0), atByte: 8)
          _ = struct$.write(UInt16(0), atByte: 18)
          return .init(struct$)
        }
      }

      public var struct$: CapnProto.StructPointer

      public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

      public func identifiers() throws(CapnProto.PointerError) -> CapnProto.List<Identifier> {
        try struct$.readList(at: 0) ?? .init()
      }

      public func initIdentifiers(count: Int) -> CapnProto.List<Identifier>? {
        struct$.initList(at: 0, count: count)
      }
    }

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    /// ID of the file.
    public var id: UInt64 {
      get { struct$.read(atByte: 0) }
      nonmutating set { _ = struct$.write(newValue, atByte: 0) }
    }

    /// Name of the file as it appeared on the command-line (minus the src-prefix).  You may use
    /// this to decide where to write the output.
    public func filename() throws(CapnProto.PointerError) -> CapnProto.Text {
      try struct$.readText(at: 0) ?? .init()
    }

    public func setFilename(_ text: Substring) -> CapnProto.Text? {
      struct$.writeText(text, at: 0)
    }

    /// List of all imported paths seen in this file.
    public func imports() throws(CapnProto.PointerError) -> CapnProto.List<Import> {
      try struct$.readList(at: 1) ?? .init()
    }

    public func initImports(count: Int) -> CapnProto.List<Import>? {
      struct$.initList(at: 1, count: count)
    }

    public func fileSourceInfo() throws(CapnProto.PointerError) -> FileSourceInfo {
      try struct$.readStruct(at: 2) ?? .init()
    }

    public func initFileSourceInfo() -> FileSourceInfo? {
      struct$.initStruct(at: 2)
    }
  }

  public var struct$: CapnProto.StructPointer

  public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

  /// All nodes parsed by the compiler, including for the files on the command line and their
  /// imports.
  public func nodes() throws(CapnProto.PointerError) -> CapnProto.List<Node> {
    try struct$.readList(at: 0) ?? .init()
  }

  public func initNodes(count: Int) -> CapnProto.List<Node>? {
    struct$.initList(at: 0, count: count)
  }

  /// Files which were listed on the command line.
  public func requestedFiles() throws(CapnProto.PointerError) -> CapnProto.List<RequestedFile> {
    try struct$.readList(at: 1) ?? .init()
  }

  public func initRequestedFiles(count: Int) -> CapnProto.List<RequestedFile>? {
    struct$.initList(at: 1, count: count)
  }

  /// Version of the `capnp` executable. Generally, code generators should ignore this, but the code
  /// generators that ship with `capnp` itself will print a warning if this mismatches since that
  /// probably indicates something is misconfigured.
  ///
  /// The first version of 'capnp' to set this was 0.6.0. So, if it's missing, the compiler version
  /// is older than that.
  public func capnpVersion() throws(CapnProto.PointerError) -> CapnpVersion {
    try struct$.readStruct(at: 2) ?? .init()
  }

  public func initCapnpVersion() -> CapnpVersion? {
    struct$.initStruct(at: 2)
  }

  /// Information about the original source code for each node, where available. This array may be
  /// omitted or may be missing some nodes if no info is available for them.
  public func sourceInfo() throws(CapnProto.PointerError) -> CapnProto.List<Node.SourceInfo> {
    try struct$.readList(at: 3) ?? .init()
  }

  public func initSourceInfo(count: Int) -> CapnProto.List<Node.SourceInfo>? {
    struct$.initList(at: 3, count: count)
  }
}

// -----------------------------------------------------------------------------
// MARK: Extensions

extension CapnProto.EnumValue<Node.Which.Discriminant> {
  public static let file: Self = .init(0)
  public static let `struct`: Self = .init(1)
  public static let `enum`: Self = .init(2)
  public static let interface: Self = .init(3)
  public static let const: Self = .init(4)
  public static let annotation: Self = .init(5)
}

extension CapnProto.EnumValue<Field.Ordinal.Which.Discriminant> {
  public static let implicit: Self = .init(0)
  public static let explicit: Self = .init(1)
}

extension CapnProto.EnumValue<Field.Which.Discriminant> {
  public static let slot: Self = .init(0)
  public static let group: Self = .init(1)
}

extension CapnProto.EnumValue<Type.AnyPointer.Unconstrained.Which.Discriminant> {
  public static let anyKind: Self = .init(0)
  public static let `struct`: Self = .init(1)
  public static let list: Self = .init(2)
  public static let capability: Self = .init(3)
}

extension CapnProto.EnumValue<Type.AnyPointer.Which.Discriminant> {
  public static let unconstrained: Self = .init(0)
  public static let parameter: Self = .init(1)
  public static let implicitMethodParameter: Self = .init(2)
}

extension CapnProto.EnumValue<Type.Which.Discriminant> {
  public static let void: Self = .init(0)
  public static let bool: Self = .init(1)
  public static let int8: Self = .init(2)
  public static let int16: Self = .init(3)
  public static let int32: Self = .init(4)
  public static let int64: Self = .init(5)
  public static let uint8: Self = .init(6)
  public static let uint16: Self = .init(7)
  public static let uint32: Self = .init(8)
  public static let uint64: Self = .init(9)
  public static let float32: Self = .init(10)
  public static let float64: Self = .init(11)
  public static let text: Self = .init(12)
  public static let data: Self = .init(13)
  public static let list: Self = .init(14)
  public static let `enum`: Self = .init(15)
  public static let `struct`: Self = .init(16)
  public static let interface: Self = .init(17)
  public static let anyPointer: Self = .init(18)
}

extension CapnProto.EnumValue<Brand.Scope.Which.Discriminant> {
  public static let bind: Self = .init(0)
  public static let inherit: Self = .init(1)
}

extension CapnProto.EnumValue<Brand.Binding.Which.Discriminant> {
  public static let unbound: Self = .init(0)
  public static let type: Self = .init(1)
}

extension CapnProto.EnumValue<Value.Which.Discriminant> {
  public static let void: Self = .init(0)
  public static let bool: Self = .init(1)
  public static let int8: Self = .init(2)
  public static let int16: Self = .init(3)
  public static let int32: Self = .init(4)
  public static let int64: Self = .init(5)
  public static let uint8: Self = .init(6)
  public static let uint16: Self = .init(7)
  public static let uint32: Self = .init(8)
  public static let uint64: Self = .init(9)
  public static let float32: Self = .init(10)
  public static let float64: Self = .init(11)
  public static let text: Self = .init(12)
  public static let data: Self = .init(13)
  public static let list: Self = .init(14)
  public static let `enum`: Self = .init(15)
  public static let `struct`: Self = .init(16)
  public static let interface: Self = .init(17)
  public static let anyPointer: Self = .init(18)
}

extension CapnProto.EnumValue<ElementSize> {
  public static let empty: Self = .init(.empty)
  public static let bit: Self = .init(.bit)
  public static let byte: Self = .init(.byte)
  public static let twoBytes: Self = .init(.twoBytes)
  public static let fourBytes: Self = .init(.fourBytes)
  public static let eightBytes: Self = .init(.eightBytes)
  public static let pointer: Self = .init(.pointer)
  public static let inlineComposite: Self = .init(.inlineComposite)
}

extension CapnProto.EnumValue<CodeGeneratorRequest.RequestedFile.FileSourceInfo.Identifier.Which.Discriminant> {
  public static let typeId: Self = .init(0)
  public static let member: Self = .init(1)
}

