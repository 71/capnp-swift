import Foundation
import Testing

@Test
func defaultsAreValid() async throws {
  let test = TestDefaults()

  #expect(test.int == 123)
  #expect(try test.text().toString() == "blah")
  #expect([Bool](try test.bits()) == [true, false, false, true])
  #expect(try test.person().name().toString() == "Alice")
  #expect(try test.person().email().toString() == "alice@example.com")
  #expect([UInt8](try test.data()) == [0xa1, 0x40, 0x33])

  #expect(
    try TestDefaults.Person(test.anyPointer.resolve()!.expectStruct()).name().toString() == "Bob"
  )

  #expect(test.unionInt == 42)
  #expect(try test.unionText() == nil)

  try await require(test, in: "schema.capnp", toBe: "()")
}

@Test
func mutateDefaults() async throws {
  let test = TestDefaults()

  test.int = 456
  #expect(test.int == 456)

  try await require(test, in: "schema.capnp", toBe: "(int = 456)")

  test.setUnionInt(1)
  #expect(test.unionInt == 1)

  #expect(test.setUnionText("hello")?.toString() == "hello")

  #expect(try test.unionText()?.toString() == "hello")

  #expect(test.unionInt == nil)
}
