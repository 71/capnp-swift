/// A list of bytes representing a nul-terminated UTF-8 encoded text string.
public struct Text {
  private(set) public var bytes: List<UInt8>

  /// Creates a `Text` instance from a list of bytes.
  public init(_ bytes: List<UInt8>) {
    self.bytes = bytes
  }

  /// Creates an empty `Text` instance.
  public init() { self.bytes = List<UInt8>() }

  /// Converts the `Text` to a `String`, returning `nil` if the text is not valid UTF-8.
  public func toString() -> String? {
    guard !bytes.isEmpty else { return "" }

    return bytes.list$.data.pointer.withMemoryRebound(to: CChar.self, capacity: 1) {
      .init(validatingCString: $0)
    }
  }

  public static func readOnly(_ string: String) -> Self {
    var string = string

    return .init(
      string.withUTF8 { utf8 in
        let data = UnsafeMessagePointer.readOnly(bytes: .init(utf8))
        let list = ListPointer(data: data, elementSize: .oneByte, count: UInt32(utf8.count))

        return List<UInt8>(unchecked: list)
      }
    )
  }
}

extension Text: Freezable {
  public func asReadOnly() -> Text { .init(bytes.asReadOnly()) }

  public mutating func freeze() -> Frozen<Text> {
    .init(unsafeFrozen: .init(bytes.freeze().value))
  }
}
