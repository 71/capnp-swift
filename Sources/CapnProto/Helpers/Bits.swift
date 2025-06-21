/// Returns a number with the specified number of bits set to 1.
///
/// For example, `oneBits(3)` returns `0b111`.
internal func oneBits<T: FixedWidthInteger>(_ bits: UInt8) -> T {
  (1 << T(bits)) - 1
}

/// Reads an unsigned integer from the given word at the specified bit offset.
internal func readUInt32(in word: Word, atBit offset: UInt8, bitWidth: UInt8) -> UInt32 {
  .init(truncatingIfNeeded: (word >> offset) & oneBits(bitWidth))
}

/// Reads a signed integer from the given word at the specified bit offset.
internal func readInt32(in word: Word, atBit offset: UInt8, bitWidth: UInt8) -> Int32 {
  let value = readUInt32(in: word, atBit: offset, bitWidth: bitWidth)

  // Sign-extend the value: https://graphics.stanford.edu/~seander/bithacks.html#VariableSignExtend.
  let mask = UInt32(1) << (bitWidth - 1)

  return .init(bitPattern: (value ^ mask) &- mask)
}
