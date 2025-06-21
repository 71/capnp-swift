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
