@0x804d690fd55cbe72;

$import "/swift.capnp".module("CapnProtoTests");

struct TestValues {
  enum Enum {
    a @0;
    b @1;
    c @2;
  }

  enum @0 :Enum = a;
  text @1 :Text;
  ints @2 :List(UInt32);
}

struct TestSelfReference {
  ref @0 :TestSelfReference;
  i @1 :UInt16;
}

struct TestDefaults {
  struct Person {
    name @0 :Text;
    email @1 :Text;
  }

  const anyPointerDefault :Person = (name = "Bob");

  int @0 :Int32 = 123;
  text @1 :Text = "blah";
  bits @2 :List(Bool) = [ true, false, false, true ];
  person @3 :Person = (name = "Alice", email = "alice@example.com");
  none @4 :Void = void;
  data @5 :Data = 0x"a1 40 33";
  anyPointer @6 :AnyPointer = TestDefaults.anyPointerDefault;

  union {
    unionInt @7 :Int32 = 42;
    unionText @8 :Text = "default text";
  }
}

interface TestInterface {}

enum TestEmptyEnum {}

struct TestEmptyStruct {}

struct TestGenerator {
  # Fields named after Swift keywords.
  default @0 :UInt32;
  class @1 :Text;
  in @2 :List(UInt8);

  # Interface and empty enum fields.
  cap @3 :TestInterface;
  emptyEnum @4 :TestEmptyEnum;

  union {
    func @5 :Void;
    init @6 :TestInterface;
    case :group {
      text @7 :Text;
      number @8 :UInt64;
      list @9 :List(UInt32);
    }
  }

  # Defaults of composite lists and empty structs.
  people @10 :List(TestDefaults.Person) = [(name = "a", email = "b"), (name = "c")];
  empty @11 :TestEmptyStruct = ();
  empties @12 :List(TestEmptyStruct) = [(), ()];
}

struct TestFirstFieldInGroup {
  # The field at ordinal 0 is in a group, after a field with a higher ordinal in code order.
  b @1 :UInt64;
  g :group {
    a @0 :UInt32;
  }
}

struct TestFirstFieldBool {
  b @0 :Bool;
  x @1 :UInt32;
}
