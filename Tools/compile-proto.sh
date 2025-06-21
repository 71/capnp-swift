#!/usr/bin/env -S bash -euo pipefail

cd "$(dirname "$0")/.."

export CAPNPC_SWIFT_MODULES="0xa93fc509624c72d9=CapnProtoSchema"

swift run capnpc-swift capnp compile \
  Sources/CapnProtoSchema/schema.capnp \
  Tests/CapnProtoTests/*.capnp
