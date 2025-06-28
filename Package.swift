// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "capnp-swift",
  platforms: [.macOS(.v15)],
  products: [
    .library(name: "CapnProto", targets: ["CapnProto", "CapnProtoSchema"]),
    .plugin(name: "CapnProtoCommand", targets: ["CapnProtoCommand"]),
    .plugin(name: "CapnProtoPlugin", targets: ["CapnProtoPlugin"]),
    .executable(name: "capnpc-swift", targets: ["capnpc-swift"]),
  ],
  targets: [
    .target(name: "CapnProto"),
    .target(name: "CapnProtoSchema", dependencies: ["CapnProto"], exclude: ["schema.capnp"]),
    .executableTarget(name: "capnpc-swift", dependencies: ["CapnProto", "CapnProtoSchema"]),
    .plugin(
      name: "CapnProtoCommand",
      capability: .command(
        intent: .custom(
          verb: "print-capnp-compile",
          description: "Print part of a capnp compile command which can be used to use Swift"
        ),
        permissions: []
      ),
      dependencies: ["capnpc-swift"]
    ),
    .plugin(name: "CapnProtoPlugin", capability: .buildTool(), dependencies: ["capnpc-swift"]),
    .testTarget(name: "CapnProtoTests", dependencies: ["CapnProto", "CapnProtoPlugin"]),
  ]
)
