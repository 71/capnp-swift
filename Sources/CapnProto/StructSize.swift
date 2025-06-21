/// The size of a `Struct`.
public struct StructSize: Sendable, Equatable, Hashable {
  /// An empty (all-zero) `StructSize`.
  public static let empty: StructSize = .init(safeDataBytes: 0, pointers: 0)

  /// The size of the object's data section in bytes.
  ///
  /// Structs' data sections are measured in words, not bytes, but in order to support lists of
  /// primitives reinterpreted as structs, we must also support data sections measured in bytes.
  public let dataBytes: UInt32

  /// The number of pointers in the object.
  public let pointers: UInt16

  /// Creates a `StructSize` with the given data size in bytes and number of pointers. Throws if
  /// this would result in an overflow when computing the total size.
  public init(dataBytes: UInt32, pointers: UInt16) throws(PointerError) {
    self.dataBytes = dataBytes
    self.pointers = pointers

    let sizeInWords = UInt64(dataBytes.divideRoundingUp(by: 8)) + UInt64(pointers)
    let sizeInBytes = sizeInWords * 8

    guard Int(exactly: sizeInBytes) != nil else {
      throw .sizeOverflow
    }
  }

  /// Creates a `StructSize` with the given data size in bytes and number of pointers, proving
  /// with the usage of an `UInt16` that the size will not overflow.
  public init(safeDataBytes: UInt16, pointers: UInt16) {
    self.dataBytes = UInt32(safeDataBytes)
    self.pointers = pointers
  }

  public init(dataBytes: UInt32) {
    self.dataBytes = dataBytes
    self.pointers = 0
  }

  public init(pointers: UInt16) {
    self.dataBytes = 0
    self.pointers = pointers
  }

  /// The number of words in the object's data section.
  public var dataWords: UInt32 { dataBytes.divideRoundingUp(by: 8) }

  /// The total size of the object (data and pointers) in words.
  public var sizeInWords: UInt32 { dataWords + UInt32(pointers) }

  /// The total size of the object (data and pointers) in bytes.
  public var sizeInBytes: Int {
    // `init()` made sure that this does not overflow.
    Int(sizeInWords) * 8
  }
}

extension StructSize: Comparable {
  public static func < (lhs: StructSize, rhs: StructSize) -> Bool {
    return (lhs.dataBytes, lhs.pointers) < (rhs.dataBytes, rhs.pointers)
  }
}
