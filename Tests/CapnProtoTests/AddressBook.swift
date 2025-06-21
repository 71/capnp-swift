import CapnProto
import Testing

@Test
func writeAddressBook() async throws {
  let message = Message()
  let addressBook = message.initRoot(of: AddressBook.self)

  let people = addressBook.initPeople(count: 2)!
  let alice = people[0]

  alice.id = 123
  #expect(alice.setName("Alice") != nil)
  #expect(alice.setEmail("alice@example.com") != nil)

  let alicePhones = alice.initPhones(count: 1)!
  let alicePhone = alicePhones[0]
  #expect(alicePhone.setNumber("555-1212") != nil)
  alicePhone.type = .mobile
  #expect(alice.employment.setSchool("MIT") != nil)

  let bob = people[1]
  bob.id = 456
  #expect(bob.setName("Bob") != nil)
  #expect(bob.setEmail("bob@example.com") != nil)

  let bobPhones = bob.initPhones(count: 2)!
  let bobPhone1 = bobPhones[0]
  #expect(bobPhone1.setNumber("555-4567") != nil)
  bobPhone1.type = .home
  let bobPhone2 = bobPhones[1]
  #expect(bobPhone2.setNumber("555-7654") != nil)
  bobPhone2.type = .work
  bob.employment.setUnemployed()

  try await require(
    addressBook,
    in: "addressbook.capnp",
    toBe: """
        (
          people = [
            (
              id = 123,
              name = "Alice",
              email = "alice@example.com",
              phones = [
                (
                  number = "555-1212",
                  type = mobile,
                ),
              ],
              employment = (
                school = "MIT",
              ),
            ),
            (
              id = 456,
              name = "Bob",
              email = "bob@example.com",
              phones = [
                (
                  number = "555-4567",
                  type = home,
                ),
                (
                  number = "555-7654",
                  type = work,
                ),
              ],
              employment = (
                unemployed = void,
              ),
            ),
          ],
        )
      """
  )
}
