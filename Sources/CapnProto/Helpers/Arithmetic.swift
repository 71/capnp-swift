extension Int {
  internal init<E>(fromUInt32 value: UInt32, orThrow error: E) throws(E) {
    guard let value = Int(exactly: value) else { throw error }

    self.init(value)
  }

  internal init(fromUInt32 value: UInt32) throws(PointerError) {
    try self.init(fromUInt32: value, orThrow: PointerError.sizeOverflow)
  }

  internal init<E>(fromUInt32 value: UInt32, multipliedBy: UInt32, orThrow error: E)
    throws(E)
  {
    let value = try Int(fromUInt32: value, orThrow: error)
    let multipliedBy = try Int(fromUInt32: multipliedBy, orThrow: error)

    self.init(try value.multiplied(by: multipliedBy, orThrow: error))
  }

  internal init(fromUInt32 value: UInt32, multipliedBy: UInt32) throws(PointerError) {
    try self.init(fromUInt32: value, multipliedBy: multipliedBy, orThrow: PointerError.sizeOverflow)
  }
}

extension FixedWidthInteger {
  internal func multiplied<E>(by other: Self, orThrow overflowError: E) throws(E) -> Self {
    let (result, overflow) = self.multipliedReportingOverflow(by: other)
    if overflow {
      throw overflowError
    }
    return result
  }

  internal func multiplied(by other: Self, or nilLiteral: ()?) -> Self? {
    let (result, overflow) = self.multipliedReportingOverflow(by: other)
    if overflow {
      return nil
    }
    return result
  }

  internal func add<E>(_ other: Self, orThrow overflowError: E) throws(E) -> Self {
    let (result, overflow) = self.addingReportingOverflow(other)
    if overflow {
      throw overflowError
    }
    return result
  }

  internal func wordsToBytes<E>(orThrow overflowError: E) throws(E) -> Int {
    if MemoryLayout<Int>.size > MemoryLayout<Self>.size {
      return Int(self) * 8
    } else {
      guard let value = Int(exactly: self) else {
        throw overflowError
      }
      return try value.multiplied(by: 8, orThrow: overflowError)
    }
  }

  internal func wordsToBytesOrNil() -> Int? {
    if MemoryLayout<Int>.size > MemoryLayout<Self>.size {
      return Int(self) * 8
    } else {
      guard let value = Int(exactly: self) else { return nil }
      let (result, overflow) = value.multipliedReportingOverflow(by: 8)
      guard !overflow else { return nil }
      return result
    }
  }

  /// Divides `self` by `by`, rounding up if there is a remainder.
  internal func divideRoundingUp(by: Self) -> Self {
    let (a, b) = self.quotientAndRemainder(dividingBy: by)

    return a + (b == 0 ? 0 : 1)
  }
}

extension UInt32 {
  internal init(widen: UInt16, multipliedBy: UInt16 = 1) {
    self = UInt32(widen) * UInt32(multipliedBy)
  }

  internal var nextPowerOfTwo: UInt32 {
    // https://jameshfisher.com/2018/03/30/round-up-power-2/
    return self <= 1 ? 1 : 1 << (Self.bitWidth - (self - 1).leadingZeroBitCount)
  }
}
