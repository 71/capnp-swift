/// A pointer to a struct's data in a `Message`.
public struct StructPointer {
  /// A pointer to the first byte of the struct.
  private(set) public var data: UnsafeMessagePointer
  /// The size of the struct.
  public let size: StructSize

  /// Creates an empty struct.
  public init() {
    self.data = .null.value
    self.size = .empty
  }

  /// Creates a struct of the specified size at the root of a new `Message`.
  public init(size: StructSize) {
    let message = Message()

    self = message.initRoot(size: size)
  }

  /// Creates a struct of the specified size whose data starts at the given pointer.
  public init(data: UnsafeMessagePointer, size: StructSize) {
    self.data = data
    self.size = size
  }
}

extension StructPointer: MessagePointer {
  public func asReadOnly() -> StructPointer { .init(data: data.asReadOnly(), size: size) }

  public mutating func freeze() -> Frozen<StructPointer> {
    .init(unsafeFrozen: .init(data: data.freeze().value, size: size))
  }
}

// -------------------------------------------------------------------------------------------------
// MARK: Read/write primitives

extension StructPointer {
  /// Reads a boolean value from the struct at the given bit offset.
  public func read(atBit offset: UInt32, defaultValue: Bool = false) -> Bool {
    let (byteOffset, bitOffset) = offset.quotientAndRemainder(dividingBy: 8)

    guard byteOffset < size.sizeInBytes else { return defaultValue }

    let bitIsSet =
      data.pointer.load(fromByteOffset: Int(byteOffset), as: UInt8.self) & (1 << bitOffset)
      != 0

    return bitIsSet != defaultValue
  }

  /// Writes a boolean value to the struct at the given bit offset.
  public func write(
    _ value: Bool,
    atBit offset: UInt32,
    defaultValue: Bool = false
  ) -> Bool {
    guard let mutablePointer = data.mutablePointer else { return false }

    let (byteOffset, bitOffset) = offset.quotientAndRemainder(dividingBy: 8)

    guard byteOffset < size.sizeInBytes else { return false }

    mutablePointer.advanced(by: Int(byteOffset)).withMemoryRebound(
      to: UInt8.self,
      capacity: 1
    ) {
      if value == defaultValue {
        $0.pointee &= ~(1 << bitOffset)
      } else {
        $0.pointee |= (1 << bitOffset)
      }
    }

    return true
  }

  /// Reads an integer from the struct at the given byte offset.
  public func read<T: FixedWidthInteger>(atByte offset: UInt32, defaultValue: T = .zero) -> T {
    guard offset + UInt32(MemoryLayout<T>.size) <= size.dataBytes else { return defaultValue }

    return data.pointer.loadLe(fromByteOffset: Int(offset), as: T.self) ^ defaultValue
  }

  /// Writes an integer to the struct at the given byte offset.
  ///
  /// If the struct is too small to hold the value, nothing will be written.
  public func write<T: FixedWidthInteger>(
    _ value: T,
    atByte offset: UInt32,
    defaultValue: T = .zero
  ) -> Bool {
    guard let mutablePointer = data.mutablePointer,
      offset + UInt32(MemoryLayout<T>.size) <= size.dataBytes
    else { return false }

    mutablePointer.storeBytes(
      of: value ^ defaultValue,
      toByteOffset: Int(offset),
      as: T.self
    )

    return true
  }

  /// Reads a float value from the struct at the given byte offset.
  public func read(atByte offset: UInt32, defaultValue: Float32 = .zero) -> Float32 {
    guard offset + 4 <= size.dataBytes else { return defaultValue }

    return .init(
      bitPattern: data.pointer.loadLe(fromByteOffset: Int(offset), as: UInt32.self)
        ^ defaultValue.bitPattern
    )
  }

  /// Writes a float value to the struct at the given byte offset.
  public func write(
    _ value: Float32,
    atByte offset: UInt32,
    defaultValue: Float32 = .zero
  ) -> Bool {
    guard let mutablePointer = data.mutablePointer, offset + 4 <= size.dataBytes else {
      return false
    }

    mutablePointer.storeBytes(
      of: value.bitPattern ^ defaultValue.bitPattern,
      toByteOffset: Int(offset),
      as: UInt32.self
    )

    return true
  }

  /// Reads a double value from the struct at the given byte offset.
  public func read(atByte offset: UInt32, defaultValue: Float64 = .zero) -> Float64 {
    guard offset + 8 <= size.dataBytes else { return defaultValue }

    return .init(
      bitPattern: data.pointer.load(fromByteOffset: Int(offset), as: UInt64.self)
        ^ defaultValue.bitPattern
    )
  }

  /// Writes a double value to the struct at the given byte offset.
  public func write(
    _ value: Float64,
    atByte offset: UInt32,
    defaultValue: Float64 = .zero
  ) -> Bool {
    guard let mutablePointer = data.mutablePointer, offset + 8 <= size.dataBytes else {
      return false
    }

    mutablePointer.storeBytes(
      of: value.bitPattern ^ defaultValue.bitPattern,
      toByteOffset: Int(offset),
      as: UInt64.self
    )

    return true
  }

  /// Reads an enum value from the struct at the given byte offset.
  public func readEnum<T: EnumOrDiscriminant>(
    atByte offset: UInt32,
    defaultValue: T = .defaultValue
  )
    -> EnumValue<T>
  {
    .init(read(atByte: offset, defaultValue: defaultValue.rawValue))
  }

  /// Reads an enum value from the struct at the given byte offset.
  public func writeEnum<T: EnumOrDiscriminant>(
    _ value: EnumValue<T>,
    atByte offset: UInt32,
    defaultValue: T = .defaultValue
  )
    -> Bool
  {
    write(value.rawValue, atByte: offset, defaultValue: defaultValue.rawValue)
  }
}

// -------------------------------------------------------------------------------------------------
// MARK: Read/write pointers

extension StructPointer {
  /// Reads the pointer at the given index.
  ///
  /// Note that there is currently no way to _write_ `AnyPointer`s, as this is harder to implement
  /// (e.g. need to handle far segments).
  public func readAnyPointer(at index: UInt16) -> AnyPointer? {
    pointer(at: index)
  }

  /// Reads and resolves the pointer at the given index.
  public func readPointer(at index: UInt16) throws(PointerError) -> ResolvedPointer? {
    try readAnyPointer(at: index)?.resolve()
  }

  /// Reads and resolves the pointer at the given index, expecting it to be a list.
  public func readList(at index: UInt16, elementSize: ListElementSize) throws(PointerError)
    -> ListPointer?
  {
    try readPointer(at: index)?.expectList()
  }

  /// Reads and resolves the pointer at the given index, expecting it to be a list of a specific
  /// type.
  public func readList<T: ListElement>(at index: UInt16, of type: T.Type = T.self)
    throws(PointerError) -> List<T>?
  {
    guard let list = try readList(at: index, elementSize: T.elementSize) else { return nil }
    guard let list = List<T>(verifying: list) else { throw .unexpectedPointerType }
    return list
  }

  /// Initializes a list at the given pointer index. Returns `nil` if the index exceeds the
  /// pointer section size.
  public func initList(at index: UInt16, count: Int, elementSize: ListElementSize) -> ListPointer? {
    guard !data.isReadOnly, let pointer = pointer(at: index) else { return nil }

    return pointer.initList(count: UInt32(count), elementSize: elementSize)
  }

  /// Initializes a list at the given pointer index. Returns `nil` if the index exceeds the
  /// pointer section size.
  public func initList<T: ListElement>(at index: UInt16, count: Int) -> List<T>? {
    guard let list$ = initList(at: index, count: count, elementSize: T.elementSize) else {
      return nil
    }
    return List<T>(unchecked: list$)
  }

  /// Reads and resolves the pointer at the given index, expecting it to be a struct.
  public func readStructPointer(at index: UInt16) throws(PointerError) -> StructPointer? {
    try readPointer(at: index)?.expectStruct()
  }

  /// Reads and resolves the pointer at the given index, expecting it to be a struct of a
  /// specific type.
  public func readStruct<T: Struct>(at index: UInt16, of type: T.Type = T.self)
    throws(PointerError) -> T?
  {
    if let pointer = try readStructPointer(at: index) {
      T(pointer)
    } else {
      nil
    }
  }

  /// Initializes a struct at the given pointer index. Returns `nil` if the index exceeds the
  /// pointer section size.
  public func initStructPointer(at index: UInt16, size: StructSize) -> StructPointer? {
    guard !data.isReadOnly, let pointer = pointer(at: index) else {
      return nil
    }
    return pointer.initStruct(size: size)
  }

  /// Initializes a struct at this pointer. Returns `nil` if the index exceeds the
  /// pointer section size.
  public func initStruct<T: Struct>(at index: UInt16) -> T? {
    guard let struct$ = initStructPointer(at: index, size: T.size) else {
      return nil
    }
    return T(struct$)
  }

  /// Reads and resolves the pointer at the given index, expecting it to be a capability.
  public func readCapability(at index: UInt16) throws(PointerError) -> AnyCapability? {
    try readPointer(at: index)?.expectCapability()
  }

  /// Writes the capability at the given pointer index.
  public func writeCapability(at index: UInt16, capabilityIndex: UInt32) -> Bool {
    guard !data.isReadOnly, let pointer = pointer(at: index) else {
      return false
    }

    pointer.writeCapability(capabilityIndex: capabilityIndex)

    return true
  }

  /// Reads and resolves the pointer at the given index, expecting it to be text.
  public func readText(at index: UInt16) throws(PointerError) -> Text? {
    if let list: List<UInt8> = try readList(at: index) {
      Text(list)
    } else {
      nil
    }
  }

  /// Initializes a text at the given pointer index. Returns `nil` if the index exceeds the
  /// pointer section size.
  public func writeText(_ value: Substring, at index: UInt16) -> Text? {
    var value = value

    return value.withUTF8 { bytes in
      guard
        let rawList = initList(
          at: index,
          count: bytes.count + 1,
          elementSize: .oneByte
        )
      else {
        return nil
      }
      let list: List<UInt8> = .init(unchecked: rawList)

      // If `initList()` returned a non-nil value, it is mutable.
      rawList.data.mutablePointer!.copyMemory(
        from: bytes.baseAddress!,
        byteCount: bytes.count
      )

      return Text(list)
    }
  }

  /// Returns the pointer at the given index, if any.
  private func pointer(at index: UInt16) -> AnyPointer? {
    guard index < size.pointers,
      let advancedRaw = try? data.advanced(byWords: size.dataWords + UInt32(index))
    else {
      return nil
    }

    return .init(unsafePointer: advancedRaw)
  }

  /// Returns the pointer at the given index, if any.
  private func mutablePointer(at index: UInt16) -> AnyPointer? {
    guard data.isMutable else { return nil }

    return pointer(at: index)
  }
}
