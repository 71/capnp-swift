import Testing

@Test
func enumValue() async throws {
  let test = TestValues()

  #expect(test.enum == .a)
  #expect(test.enum.orNil == .a)
  #expect(test.enum.rawValue == 0)

  test.enum = .b
  #expect(test.enum == .b)
  #expect(test.enum.orNil == .b)
  #expect(test.enum.rawValue == 1)

  test.enum.rawValue = 2
  #expect(test.enum == .c)
  #expect(test.enum.orNil == .c)
  #expect(test.enum.rawValue == 2)

  test.enum.rawValue = 3
  #expect(test.enum.orNil == nil)
  #expect(test.enum.rawValue == 3)

  test.enum = .a
  #expect(test.enum == .a)
  #expect(test.enum.orNil == .a)
  #expect(test.enum.rawValue == 0)
}

@Test
func primitiveListCount() async throws {
  let test = TestValues()
  let ints = try #require(test.initInts(count: 3))

  #expect(ints.count == 3)
  #expect(ints.write(7, at: 2))
  #expect(try test.ints().count == 3)
  #expect(try test.ints()[2] == 7)
}
