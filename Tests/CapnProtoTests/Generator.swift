import CapnProto
import Testing

@Test
func keywordFields() throws {
  let test = TestGenerator()

  test.default = 7
  _ = try #require(test.setClass("text"))
  _ = try #require(test.initIn(count: 2))

  #expect(test.default == 7)
  #expect(try test.class().toString() == "text")
  #expect(try test.in().count == 2)

  test.setFunc()
  guard case .func = try test.which() else {
    Issue.record("expected .func")
    return
  }
}

@Test
func interfaceFields() throws {
  let test = TestGenerator()

  #expect(try test.cap() == nil)
  test.setCap(.init(capabilityIndex: 3))
  #expect(try test.cap()?.capabilityIndex == 3)

  test.setInit(.init(capabilityIndex: 5))
  guard case .`init`(let capability) = try test.which() else {
    Issue.record("expected .init")
    return
  }
  #expect(capability?.capabilityIndex == 5)
  #expect(try test.`init`()?.capabilityIndex == 5)
}

@Test
func unionGroupInitClearsPointers() throws {
  let test = TestGenerator()
  test.default = 7

  let group = test.initCase()
  _ = try #require(group.setText("hello"))
  group.number = 42
  _ = try #require(group.initList(count: 3))

  // Re-initializing the group must clear its fields, and only its fields.
  let cleared = test.initCase()

  #expect(try cleared.text().bytes.isEmpty)
  #expect(cleared.number == 0)
  #expect(try cleared.list().isEmpty)
  #expect(test.default == 7)
}

@Test
func compositeAndEmptyDefaults() throws {
  let test = TestGenerator()

  let people = try test.people()
  #expect(people.count == 2)
  #expect(try people[0].name().toString() == "a")
  #expect(try people[0].email().toString() == "b")
  #expect(try people[1].name().toString() == "c")
  #expect(try people[1].email().toString() == "")

  #expect(try test.empty().struct$.size == .empty)
  #expect(try test.empties().count == 2)
}

@Test
func emptyEnum() throws {
  let test = TestGenerator()

  #expect(test.emptyEnum.rawValue == 0)
  #expect(test.emptyEnum.orNil == nil)
}

@Test
func firstFieldSizeUsesLayout() throws {
  // The field with ordinal 0 is in a group, and is a `UInt32` at offset 0.
  #expect(TestFirstFieldInGroup.firstFieldSize == .fourBytes)
  // A list of bools cannot be upgraded to a list of structs.
  #expect(TestFirstFieldBool.firstFieldSize == nil)
}
