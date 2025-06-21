extension UnsafeRawBufferPointer {
  internal func advanced(by byteCount: Int) -> Self {
    .init(
      start: baseAddress!.advanced(by: byteCount),
      count: count - byteCount
    )
  }

  internal mutating func advance(by byteCount: Int) {
    self = advanced(by: byteCount)
  }

  internal func loadLe<T: FixedWidthInteger>(fromByteOffset offset: Int = 0, as type: T.Type) -> T {
    return load(fromByteOffset: offset, as: T.self).littleEndian
  }
}

extension UnsafeMutableRawBufferPointer {
  internal func advanced(by byteCount: Int) -> Self {
    .init(
      start: baseAddress!.advanced(by: byteCount),
      count: count - byteCount
    )
  }

  internal mutating func advance(by byteCount: Int) {
    self = advanced(by: byteCount)
  }
}

extension UnsafeBufferPointer {
  package func advanced(by: Int) -> Self {
    .init(
      start: baseAddress!.advanced(by: by),
      count: count - by
    )
  }
}

extension UnsafeRawPointer {
  internal func loadLe<T: FixedWidthInteger>(fromByteOffset offset: Int = 0, as type: T.Type) -> T {
    return load(fromByteOffset: offset, as: T.self).littleEndian
  }
}
