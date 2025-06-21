// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "CapnProto",
  platforms: [.macOS(.v15)],
  products: [
    .library(name: "CapnProto", targets: ["CapnProto", "CapnProtoSchema"]),
    .executable(name: "capnpc-swift", targets: ["capnpc-swift"]),
  ],
  targets: [
    .target(name: "CapnProto", path: "Sources/CapnProto"),
    .target(
      name: "CapnProtoSchema",
      dependencies: ["CapnProto"],
      path: "Sources/CapnProtoSchema",
      exclude: ["schema.capnp"]
    ),
    .executableTarget(
      name: "capnpc-swift",
      dependencies: ["CapnProto", "CapnProtoSchema"],
      path: "Sources/capnpc-swift"
    ),
    .testTarget(
      name: "CapnProtoTests",
      dependencies: ["CapnProto"],
      exclude: ["addressbook.capnp", "schema.capnp"]
    ),
  ]
)
