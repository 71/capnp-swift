@0xdbaa7e674e81c2c3;

$module("CapnProto");

annotation module @0xb12304ebb885c9c2 (file) :Text;
# Sets the Swift module name for the generated code.
#
# If this annotation cannot be applied to the module (e.g. because it was taken from another project
# which does not support Swift code generation), the `CAPNPC_SWIFT_MODULES` environment variable can
# be used to set the module name. It is a list of pairs `0xABCD=ModuleName`, where `0xABCD` is the
# 64-bit file identifier of the imported Cap'n Proto schema file, and `ModuleName` is the desired
# Swift module name. The pairs are separated by colons `:`, except on Windows where they are
# separated by semicolons `;`.
