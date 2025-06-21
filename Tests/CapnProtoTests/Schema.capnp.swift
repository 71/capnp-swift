// Automatically generated from Tests/CapnProtoTests/schema.capnp @0x804d690fd55cbe72.
// See https://github.com/71/capnp-swift for more information.
//
// swift-format-ignore-file
import CapnProto
import CapnProtoSchema

public struct TestValues: CapnProto.Struct {
  public static let id: UInt64 = 0xa509147fb9eb9174
  public static let size: CapnProto.StructSize = .init(safeDataBytes: 8, pointers: 2)
  public static let firstFieldSize: CapnProto.ListElementSize? = .twoBytes

  public enum Enum: UInt16, CapnProto.Enum {
    public static let id: UInt64 = 0x836e1c46c9626f71
    public static let defaultValue: Self = .a
    public static let maxValue: Self = .c

    case a = 0
    case b = 1
    case c = 2
  }

  public var struct$: CapnProto.StructPointer

  public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

  public var `enum`: CapnProto.EnumValue<Enum> {
    get { struct$.readEnum(atByte: 0, defaultValue: .a) }
    nonmutating set { _ = struct$.writeEnum(newValue, atByte: 0, defaultValue: .a) }
  }

  public func text() throws(CapnProto.PointerError) -> CapnProto.Text {
    try struct$.readText(at: 0) ?? .init()
  }

  public func setText(_ text: Substring) -> CapnProto.Text? {
    struct$.writeText(text, at: 0)
  }

  public func ints() throws(CapnProto.PointerError) -> CapnProto.List<UInt32> {
    try struct$.readList(at: 1) ?? .init()
  }

  public func initInts(count: Int) -> CapnProto.List<UInt32>? {
    struct$.initList(at: 1, count: count)
  }
}

public struct TestSelfReference: CapnProto.Struct {
  public static let id: UInt64 = 0xab4b2243e9a92af6
  public static let size: CapnProto.StructSize = .init(safeDataBytes: 8, pointers: 1)
  public static let firstFieldSize: CapnProto.ListElementSize? = .pointer

  public var struct$: CapnProto.StructPointer

  public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

  public func ref() throws(CapnProto.PointerError) -> TestSelfReference {
    try struct$.readStruct(at: 0) ?? .init()
  }

  public func initRef() -> TestSelfReference? {
    struct$.initStruct(at: 0)
  }

  public var i: UInt16 {
    get { struct$.read(atByte: 0) }
    nonmutating set { _ = struct$.write(newValue, atByte: 0) }
  }
}

public struct TestDefaults: CapnProto.Struct {
  public static let id: UInt64 = 0x8b903dddd6ad9823
  public static let size: CapnProto.StructSize = .init(safeDataBytes: 16, pointers: 6)
  public static let firstFieldSize: CapnProto.ListElementSize? = .fourBytes

  public struct Person: CapnProto.Struct {
    public static let id: UInt64 = 0xc899fdba225f6665
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 0, pointers: 2)
    public static let firstFieldSize: CapnProto.ListElementSize? = .pointer

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    public func name() throws(CapnProto.PointerError) -> CapnProto.Text {
      try struct$.readText(at: 0) ?? .init()
    }

    public func setName(_ text: Substring) -> CapnProto.Text? {
      struct$.writeText(text, at: 0)
    }

    public func email() throws(CapnProto.PointerError) -> CapnProto.Text {
      try struct$.readText(at: 1) ?? .init()
    }

    public func setEmail(_ text: Substring) -> CapnProto.Text? {
      struct$.writeText(text, at: 1)
    }
  }

  public static let anyPointerDefault: CapnProto.Frozen<Person> =  // 0xff91833c2f4271eb
    .init { .init(.init(data: .readOnly(words: [0x2200000005, 0x0, 0x626f42]), size: .init(pointers: 2))) }

  public var struct$: CapnProto.StructPointer

  public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

  public enum Which {
    public enum Discriminant: UInt16, CapnProto.EnumOrDiscriminant {
      public static let defaultValue: Discriminant = .unionInt
      public static let maxValue: Discriminant = .unionText

      case unionInt = 0
      case unionText = 1
    }

    case unionInt(Int32)
    case unionText(CapnProto.Text)
  }

  public var whichDiscriminant: CapnProto.EnumValue<Which.Discriminant> {
    struct$.readEnum(atByte: 8, defaultValue: .unionInt)
  }

  public func which() throws(CapnProto.PointerError) -> Which? {
    switch whichDiscriminant.rawValue {
    case 0: .unionInt(struct$.read(atByte: 4))
    case 1: .unionText(try struct$.readText(at: 5) ?? .init())
    default: nil
    }
  }

  public var int: Int32 {
    get { struct$.read(atByte: 0, defaultValue: 123) }
    nonmutating set { _ = struct$.write(newValue, atByte: 0, defaultValue: 123) }
  }

  public func text() throws(CapnProto.PointerError) -> CapnProto.Text {
    try struct$.readText(at: 0) ?? Self.defaultText.value
  }

  public func setText(_ text: Substring) -> CapnProto.Text? {
    struct$.writeText(text, at: 0)
  }

  public func bits() throws(CapnProto.PointerError) -> CapnProto.List<Bool> {
    try struct$.readList(at: 1) ?? Self.defaultBits.value
  }

  public func initBits(count: Int) -> CapnProto.List<Bool>? {
    struct$.initList(at: 1, count: count)
  }

  public func person() throws(CapnProto.PointerError) -> Person {
    try struct$.readStruct(at: 2) ?? Self.defaultPerson.value
  }

  public func initPerson() -> Person? {
    struct$.initStruct(at: 2)
  }

  public var none: CapnProto.VoidValue {
    get { .init() }
    nonmutating set { _ = newValue }
  }

  public func data() throws(CapnProto.PointerError) -> CapnProto.List<UInt8> {
    try struct$.readList(at: 3) ?? Self.defaultData.value
  }

  public func initData(count: Int) -> CapnProto.List<UInt8>? {
    struct$.initList(at: 3, count: count)
  }

  public var anyPointer: CapnProto.AnyPointer {
    struct$.readAnyPointer(at: 4)?.orNil ?? Self.defaultAnyPointer.value
  }

  /// Part of a union.
  public var unionInt: Int32? {
    whichDiscriminant.rawValue == 0 ? struct$.read(atByte: 4, defaultValue: 42) : nil
  }

  public func setUnionInt(_ newValue: Int32) {
    if struct$.write(UInt16(0), atByte: 8) {
      _ = struct$.write(newValue, atByte: 4, defaultValue: 42)
    }
  }

  /// Part of a union.
  public func unionText() throws(CapnProto.PointerError) -> CapnProto.Text? {
    whichDiscriminant.rawValue == 1 ? try struct$.readText(at: 5) ?? Self.defaultUnionText.value : nil
  }

  public func setUnionText(_ text: Substring) -> CapnProto.Text? {
    struct$.write(UInt16(1), atByte: 8) ? struct$.writeText(text, at: 5) : nil
  }
}

// -----------------------------------------------------------------------------
// MARK: Extensions

extension CapnProto.EnumValue<TestValues.Enum> {
  public static let a: Self = .init(.a)
  public static let b: Self = .init(.b)
  public static let c: Self = .init(.c)
}

extension CapnProto.EnumValue<TestDefaults.Which.Discriminant> {
  public static let unionInt: Self = .init(0)
  public static let unionText: Self = .init(1)
}

extension TestDefaults {
  private static let defaultText: CapnProto.Frozen<CapnProto.Text> = .init {
    .readOnly("blah")
  }
  private static let defaultBits: CapnProto.Frozen<CapnProto.List<Bool>> = .init {
    .init(unchecked: .init(data: .readOnly(words: [0x9]), elementSize: .oneBit, count: 4))
  }
  private static let defaultPerson: CapnProto.Frozen<Person> = .init {
    .init(.init(data: .readOnly(words: [0x3200000005, 0x9200000005, 0x6563696c41, 0x7865406563696c61, 0x6f632e656c706d61, 0x6d]), size: .init(pointers: 2)))
  }
  private static let defaultData: CapnProto.Frozen<CapnProto.List<UInt8>> = .init {
    .init(unchecked: .init(data: .readOnly(words: [0x3340a1]), elementSize: .oneByte, count: 3))
  }
  private static let defaultAnyPointer: CapnProto.Frozen<AnyPointer> = .init {
    .init(unsafePointer: .readOnly(words: [0x2000000000000, 0x2200000005, 0x0, 0x626f42]))
  }
  private static let defaultUnionText: CapnProto.Frozen<CapnProto.Text> = .init {
    .readOnly("default text")
  }
}

