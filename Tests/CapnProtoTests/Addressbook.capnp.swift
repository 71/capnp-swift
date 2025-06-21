// Automatically generated from Tests/CapnProtoTests/addressbook.capnp @0x9eb32e19f86ee174.
// See https://github.com/71/capnp-swift for more information.
//
// swift-format-ignore-file
import CapnProto
import CapnProtoSchema

public struct Person: CapnProto.Struct {
  public static let id: UInt64 = 0x98808e9832e8bc18
  public static let size: CapnProto.StructSize = .init(safeDataBytes: 8, pointers: 4)
  public static let firstFieldSize: CapnProto.ListElementSize? = .fourBytes

  public struct PhoneNumber: CapnProto.Struct {
    public static let id: UInt64 = 0x814e90b29c9e8ad0
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 8, pointers: 1)
    public static let firstFieldSize: CapnProto.ListElementSize? = .pointer

    public enum `Type`: UInt16, CapnProto.Enum {
      public static let id: UInt64 = 0x91e0bd04d585062f
      public static let defaultValue: Self = .mobile
      public static let maxValue: Self = .work

      case mobile = 0
      case home = 1
      case work = 2
    }

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    public func number() throws(CapnProto.PointerError) -> CapnProto.Text {
      try struct$.readText(at: 0) ?? .init()
    }

    public func setNumber(_ text: Substring) -> CapnProto.Text? {
      struct$.writeText(text, at: 0)
    }

    public var type: CapnProto.EnumValue<`Type`> {
      get { struct$.readEnum(atByte: 0) }
      nonmutating set { _ = struct$.writeEnum(newValue, atByte: 0) }
    }
  }

  /// Generated for group `employment`.
  public struct Employment: CapnProto.Struct {
    public static let id: UInt64 = 0xbb0b2bd4bdc3693d
    public static let size: CapnProto.StructSize = .init(safeDataBytes: 8, pointers: 4)
    public static let firstFieldSize: CapnProto.ListElementSize? = nil

    public var struct$: CapnProto.StructPointer

    public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

    public enum Which {
      public enum Discriminant: UInt16, CapnProto.EnumOrDiscriminant {
        public static let defaultValue: Discriminant = .unemployed
        public static let maxValue: Discriminant = .selfEmployed

        case unemployed = 0
        case employer = 1
        case school = 2
        case selfEmployed = 3
      }

      case unemployed
      case employer(CapnProto.Text)
      case school(CapnProto.Text)
      case selfEmployed
    }

    public var whichDiscriminant: CapnProto.EnumValue<Which.Discriminant> {
      struct$.readEnum(atByte: 4, defaultValue: .unemployed)
    }

    public func which() throws(CapnProto.PointerError) -> Which? {
      switch whichDiscriminant.rawValue {
      case 0: .unemployed
      case 1: .employer(try struct$.readText(at: 3) ?? .init())
      case 2: .school(try struct$.readText(at: 3) ?? .init())
      case 3: .selfEmployed
      default: nil
      }
    }

    /// Part of a union.
    public var unemployed: CapnProto.VoidValue? {
      whichDiscriminant.rawValue == 0 ? .init() : nil
    }

    public func setUnemployed() {
      _ = struct$.write(UInt16(0), atByte: 4)
    }

    /// Part of a union.
    public func employer() throws(CapnProto.PointerError) -> CapnProto.Text? {
      whichDiscriminant.rawValue == 1 ? try struct$.readText(at: 3) ?? .init() : nil
    }

    public func setEmployer(_ text: Substring) -> CapnProto.Text? {
      struct$.write(UInt16(1), atByte: 4) ? struct$.writeText(text, at: 3) : nil
    }

    /// Part of a union.
    public func school() throws(CapnProto.PointerError) -> CapnProto.Text? {
      whichDiscriminant.rawValue == 2 ? try struct$.readText(at: 3) ?? .init() : nil
    }

    public func setSchool(_ text: Substring) -> CapnProto.Text? {
      struct$.write(UInt16(2), atByte: 4) ? struct$.writeText(text, at: 3) : nil
    }

    /// We assume that a person is only one of these.
    ///
    /// Part of a union.
    public var selfEmployed: CapnProto.VoidValue? {
      whichDiscriminant.rawValue == 3 ? .init() : nil
    }

    public func setSelfEmployed() {
      _ = struct$.write(UInt16(3), atByte: 4)
    }
  }

  public var struct$: CapnProto.StructPointer

  public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

  public var id: UInt32 {
    get { struct$.read(atByte: 0) }
    nonmutating set { _ = struct$.write(newValue, atByte: 0) }
  }

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

  public func phones() throws(CapnProto.PointerError) -> CapnProto.List<PhoneNumber> {
    try struct$.readList(at: 2) ?? .init()
  }

  public func initPhones(count: Int) -> CapnProto.List<PhoneNumber>? {
    struct$.initList(at: 2, count: count)
  }

  public var employment: Employment { .init(struct$) }
}

public struct AddressBook: CapnProto.Struct {
  public static let id: UInt64 = 0xf934d9b354a8a134
  public static let size: CapnProto.StructSize = .init(safeDataBytes: 0, pointers: 1)
  public static let firstFieldSize: CapnProto.ListElementSize? = .pointer

  public var struct$: CapnProto.StructPointer

  public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }

  public func people() throws(CapnProto.PointerError) -> CapnProto.List<Person> {
    try struct$.readList(at: 0) ?? .init()
  }

  public func initPeople(count: Int) -> CapnProto.List<Person>? {
    struct$.initList(at: 0, count: count)
  }
}

// -----------------------------------------------------------------------------
// MARK: Extensions

extension CapnProto.EnumValue<Person.PhoneNumber.`Type`> {
  public static let mobile: Self = .init(.mobile)
  public static let home: Self = .init(.home)
  public static let work: Self = .init(.work)
}

extension CapnProto.EnumValue<Person.Employment.Which.Discriminant> {
  public static let unemployed: Self = .init(0)
  public static let employer: Self = .init(1)
  public static let school: Self = .init(2)
  public static let selfEmployed: Self = .init(3)
}

