/// Size of an element of a list.
///
/// https://capnproto.org/encoding.html#lists
public enum ListElementSize: Sendable, Equatable, Hashable, Comparable {
  public enum Raw: UInt8, Sendable {
    case zero = 0
    case oneBit = 1
    case oneByte = 2
    case twoBytes = 3
    case fourBytes = 4
    case eightBytes = 5
    case pointer = 6
    case composite = 7

    /// Returns the number of bits needed to store an element of this size, or nil if this is
    /// `composite`.
    public var bits: UInt8? {
      switch self {
      case .zero: return 0
      case .oneBit: return 1
      case .oneByte: return 8
      case .twoBytes: return 16
      case .fourBytes: return 32
      case .eightBytes: return 64
      case .pointer: return 64
      case .composite: return nil
      }
    }

    public init?(sizeBits: UInt8) {
      switch sizeBits {
      case 0: self = .zero
      case 1: self = .oneBit
      case 2: self = .oneByte
      case 3: self = .twoBytes
      case 4: self = .fourBytes
      case 5: self = .eightBytes
      case 6: self = .pointer
      case 7: self = .composite
      default: return nil
      }
    }
  }

  case zero
  case oneBit
  case oneByte
  case twoBytes
  case fourBytes
  case eightBytes
  case pointer
  case composite(StructSize)

  public var rawValue: Raw {
    switch self {
    case .zero: .zero
    case .oneBit: .oneBit
    case .oneByte: .oneByte
    case .twoBytes: .twoBytes
    case .fourBytes: .fourBytes
    case .eightBytes: .eightBytes
    case .pointer: .pointer
    case .composite(_): .composite
    }
  }

  public var bits: UInt64 {
    switch self {
    case .zero: 0
    case .oneBit: 1
    case .oneByte: 8
    case .twoBytes: 16
    case .fourBytes: 32
    case .eightBytes: 64
    case .pointer: 64
    case .composite(let size): UInt64(size.sizeInWords) * 64
    }
  }

  public init?(rawValue: Raw) {
    switch rawValue {
    case .zero: self = .zero
    case .oneBit: self = .oneBit
    case .oneByte: self = .oneByte
    case .twoBytes: self = .twoBytes
    case .fourBytes: self = .fourBytes
    case .eightBytes: self = .eightBytes
    case .pointer: self = .pointer
    case .composite: return nil
    }
  }
}
