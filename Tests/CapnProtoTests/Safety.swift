import CapnProto
import Testing

@Test
func traversalLimit() throws {
  let test = TestSelfReference()
  var current = test

  for i in 0..<UnsafeMessagePointer.defaultTraversalLimit + 1 {
    current.i = i
    current = current.initRef()!
  }

  current = test
  for i in 0..<UnsafeMessagePointer.defaultTraversalLimit {
    try #require(current.i == i)
    current = try current.ref()
  }

  #expect(throws: PointerError.traversalLimitExceeded) {
    try current.ref()
  }
}

@Test
func badData() throws {
  let message = Message(segmentWords: [.max])!

  #expect(throws: PointerError.self) {
    _ = try message.root(of: TestValues.self)
  }
}
