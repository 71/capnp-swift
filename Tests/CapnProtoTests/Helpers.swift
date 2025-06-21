import CapnProto
import Foundation
import Testing

/// Runs `capnp` with the given arguments (and optional `stdin` data), then returns its `stdout`.
func capnp(arguments: [String], stdin: Data? = nil) async throws -> Data {
  let capnp = Process()
  let stdinPipe = stdin.map { _ in Pipe() }
  let stdoutPipe = Pipe()

  capnp.executableURL = findInPath("capnp")
  capnp.arguments = arguments
  capnp.standardOutput = stdoutPipe

  if let stdinPipe {
    capnp.standardInput = stdinPipe

    try stdinPipe.fileHandleForWriting.write(contentsOf: stdin!)
    try stdinPipe.fileHandleForWriting.close()
  }

  return try await withCheckedThrowingContinuation { continuation in
    capnp.terminationHandler = { process in
      do {
        try #require(process.terminationStatus == 0)

        continuation.resume(
          returning: stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        )
      } catch {
        continuation.resume(throwing: error)
      }
    }

    do {
      try capnp.run()
    } catch {
      continuation.resume(throwing: error)
    }
  }
}

/// Serializes the given `capnp` text (as a struct of the given `type` in the given `schema`) into
/// a message, and returns the words of that message.
func capnp(schema: Substring, type: Substring, dynamic capnp: Substring) async throws
  -> [Word]
{
  let outputBytes = try await CapnProtoTests.capnp(
    arguments: [
      "convert", "text:flat", "Tests/CapnProtoTests/\(schema)", String(type),
    ],
    stdin: capnp.data(using: .utf8)!
  )

  try #require(outputBytes.count % 8 == 0)

  return .init(unsafeUninitializedCapacity: outputBytes.count / 8) {
    (buffer, initializedCount) in
    #expect(outputBytes.copyBytes(to: buffer) == outputBytes.count)

    initializedCount = outputBytes.count / 8
  }
}

/// `#require`s (with `Testing`) that `struct_`'s `Message` matches the given `capnp` text.
func require(_ struct_: some Struct, in schema: Substring, toBe capnp: Substring) async throws {
  let qualifiedTypeName = String(reflecting: type(of: struct_))
  let typeName = qualifiedTypeName[
    qualifiedTypeName.index(after: qualifiedTypeName.firstIndex(of: ".")!)...
  ]

  try await require(struct_.struct$.data.message, in: schema, of: typeName, toBe: capnp)
}

/// `#require`s (with `Testing`) that `Message` (of type `type` in file `schema`) matches the given
/// `capnp` text.
func require(
  _ message: Message,
  in schema: Substring,
  of type: Substring,
  toBe capnpText: Substring
)
  async throws
{
  let actual = message.words
  let expected = try await capnp(schema: schema, type: type, dynamic: capnpText)

  if actual != expected {
    let actualText = try await message.formatToText(schema: schema, type: type)

    #expect(actualText == capnpText)
    try #require(actual == expected)
  }
}

extension AnyPointer {
  /// The words of the message that this pointer points to.
  var words: [CapnProto.Word] { unsafePointer.message.words }
}

extension Message {
  /// The words of the message.
  var words: [CapnProto.Word] { .init(firstSegment.buffer) }

  /// Converts the message to Cap'n Proto text format given its schema and type.
  func formatToText(schema: Substring, type: Substring) async throws -> String {
    let outputBytes = try await capnp(
      arguments: ["convert", "flat:text", "Tests/CapnProtoTests/\(schema)", String(type)],
      stdin: .init(firstSegment.buffer.withMemoryRebound(to: UInt8.self) { $0 })
    )

    return .init(data: outputBytes, encoding: .utf8)!
  }
}

private func findInPath(_ exe: String) -> URL {
  let path = ProcessInfo.processInfo.environment["PATH"]!

  for dir in path.split(separator: ":") {
    let fullPath = "\(dir)/\(exe)"

    if FileManager.default.isExecutableFile(atPath: fullPath) {
      return URL(fileURLWithPath: fullPath, isDirectory: false)
    }
  }

  fatalError("cannot find \(exe) in PATH")
}
