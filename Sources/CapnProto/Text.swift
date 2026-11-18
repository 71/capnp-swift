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
  ///
  /// The trailing NUL byte is dropped if present. Only `bytes.count` bytes are read, so text
  /// without a NUL terminator is accepted rather than read past its end, and embedded NUL
  /// bytes are kept.
  public func toString() -> String? {
    var utf8 = bytes.bytes()

    if utf8.last == 0 {
      utf8 = .init(rebasing: utf8.dropLast())
    }

    return String(validating: utf8, as: UTF8.self)
  }

  public static func readOnly(_ string: String) -> Self {
    var string = string

    return .init(
      string.withUTF8 { utf8 in
        // +1 for the NUL terminator. The rest of the last word is zero-filled as well.
        let byteCount = utf8.count + 1
        var words = [Word](repeating: 0, count: byteCount.divideRoundingUp(by: 8))
        words.withUnsafeMutableBytes { $0.copyMemory(from: .init(utf8)) }

        let data = UnsafeMessagePointer.readOnly(words: words)
        let list = ListPointer(data: data, elementSize: .oneByte, count: UInt32(byteCount))

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
