extension AnyPointer {
  /// Performs a copy of the pointer and the data it points to, returning a new `AnyPointer` that
  /// points to the root of a new `Message`.
  public func copy() throws(PointerError) -> AnyPointer {
    let messageWords = try computeWordSize()
    let message = Message(withInitialWordCapacity: messageWords)

    try message.rootPointer.copy(from: self)

    assert(message.segmentCount == 1)
    assert(message.firstSegment.data.words == messageWords)

    return message.rootPointer
  }

  package func copy(from pointer: AnyPointer) throws(PointerError) {
    switch try pointer.resolve() {
    case nil:
      break
    case .capability(let capability):
      writeCapability(capabilityIndex: capability.capabilityIndex)

    case .list(let list):
      try initList(count: list.rawCount, elementSize: list.elementSize).copy(from: list)

    case .struct(let struct_):
      try initStruct(size: struct_.size).copy(from: struct_)
    }
  }

  /// Computes the size of the pointer (and the data it points to) in words, assuming a single
  /// segment (no far pointers).
  fileprivate func computeWordSize() throws(PointerError) -> UInt32 {
    switch try resolve() {
    case nil: 1  // Null pointer is encoded as a 0 word.
    case .capability: 1
    case .list(let list): try list.computeWordSize()
    case .struct(let struct_): try struct_.computeWordSize()
    }
  }
}

extension List {
  /// Performs a copy of the list and the data it points to, returning a new `List` that points to
  /// the root of a new `Message`.
  public func copy() throws(PointerError) -> List<T> {
    .init(unchecked: try list$.copy())
  }
}

extension ListPointer {
  /// Performs a copy of the list and the data it points to, returning a new `ListPointer` that
  /// points to the root of a new `Message`.
  public func copy() throws(PointerError) -> ListPointer {
    try AnyPointer(unsafePointer: data).copy().resolve()!.expectList()
  }

  package func copy(from list: ListPointer) throws(PointerError) {
    switch list.elementSize {
    case .zero:
      break
    case .oneBit:
      copy(from: list, bitsPerElement: 1)
    case .oneByte:
      copy(from: list, bitsPerElement: 8)
    case .twoBytes:
      copy(from: list, bitsPerElement: 16)
    case .fourBytes:
      copy(from: list, bitsPerElement: 32)
    case .eightBytes:
      copy(from: list, bitsPerElement: 64)

    case .pointer:
      for i in 0..<list.count {
        let source: AnyPointer = try list.read(at: i)
        let target: AnyPointer = try read(at: i)

        try target.copy(from: source)
      }

    case .composite(let size):
      for i in 0..<list.rawCount {
        let sourcePointer = try list.data.advanced(byWords: i * size.dataWords)
        let source = StructPointer(data: sourcePointer, size: size)
        let target = initStruct(at: Int(i))!

        try target.copy(from: source)
      }
    }
  }

  private func copy(from list: ListPointer, bitsPerElement: UInt32) {
    data.assertMutablePointer.copyMemory(
      from: list.data.pointer,
      byteCount: Int(list.rawCount * bitsPerElement).divideRoundingUp(by: 8)
    )
  }

  fileprivate func computeWordSize() throws(PointerError) -> UInt32 {
    // Add 1 for the pointer word.
    var dataWords: UInt32 = 0

    switch elementSize {
    case .zero: dataWords = 0
    case .oneBit: dataWords = rawCount.divideRoundingUp(by: 64)
    case .oneByte: dataWords = rawCount.divideRoundingUp(by: 8)
    case .twoBytes: dataWords = rawCount.divideRoundingUp(by: 4)
    case .fourBytes: dataWords = rawCount.divideRoundingUp(by: 2)
    case .eightBytes: dataWords = rawCount

    case .pointer:
      for i in 0..<Int(rawCount) {
        dataWords += try pointer(at: i).computeWordSize()
      }

    case .composite(let size):
      dataWords = 1  // Tag word.

      for i in 0..<Int(rawCount) {
        let struct_ = StructPointer(
          data: data.advanced(byBytes: i * size.sizeInBytes),
          size: size
        )

        dataWords += try struct_.computeWordSize()
      }
    }

    return 1 + dataWords  // Add 1 for the pointer word.
  }
}

extension Struct {
  /// Performs a copy of the struct and the data it points to, returning a new `Struct` that
  /// points to the root of a new `Message`.
  public func copy() throws(PointerError) -> Self {
    .init(try struct$.copy())
  }
}

extension StructPointer {
  /// Performs a copy of the struct and the data it points to, returning a new `StructPointer`
  /// that points to the root of a new `Message`.
  public func copy() throws(PointerError) -> StructPointer {
    try AnyPointer(unsafePointer: data).copy().resolve()!.expectStruct()
  }

  package func copy(from struct_: StructPointer) throws(PointerError) {
    data.assertMutablePointer.copyMemory(
      from: struct_.data.pointer,
      byteCount: Int(struct_.size.dataBytes)
    )

    for i in 0..<struct_.size.pointers {
      guard let source = struct_.readAnyPointer(at: i) else {
        throw .pointerOutOfRange
      }
      let target = readAnyPointer(at: i)!

      try target.copy(from: source)
    }
  }

  fileprivate func computeWordSize() throws(PointerError) -> UInt32 {
    var words = 1 + size.dataWords

    for i in 0..<size.pointers {
      words += try readAnyPointer(at: i)?.computeWordSize() ?? 1
    }

    return words
  }
}
