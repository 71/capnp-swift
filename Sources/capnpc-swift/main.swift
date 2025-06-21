import CapnProto
import CapnProtoSchema
import Foundation

//
// Validate command line arguments.

#if DEBUG
  let DEBUG = true
#else
  let DEBUG = false
#endif

if !DEBUG && CommandLine.argc != 1 {
  fputs("Usage: capnp compile --output=\(CommandLine.arguments[0]) <schema.capnp>\n", stderr)

  if CommandLine.arguments.contains(where: { $0 == "--help" || $0 == "-h" }) {
    exit(0)
  } else {
    exit(1)
  }
}

//
// Read and process data.

var warnings = [String]()

let message = try readStdin()
let request = try message.root(of: CodeGeneratorRequest.self)
let generatedFiles = try generateFiles(
  for: request,
  fileIdToModuleMap: envModuleMap(),
  warnWith: { warnings.append($0) }
)

for warning in warnings {
  fputs("[capnp-swift] WARNING: \(warning)\n", stderr)
}

var exitCode: Int32 = 0

for (fileName, contents) in generatedFiles {
  if !write(to: fileName, contents: contents) {
    exitCode = 1
  }
}

exit(exitCode)

//
// Helpers.

/// Reads all of `stdin` into a `Data` object. Exits on error.
func readStdin() throws -> Message {
  let chunkSize = 4096
  var messageDecoder = MessageStreamDecoder()

  #if DEBUG
    if CommandLine.argc > 1 {
      let capnp = CommandLine.arguments[1]
      let capnpProcess = Process()
      let outputPipe = Pipe()

      let capnpPath =
        if capnp.contains("/") {
          capnp
        } else {
          // If the path does not contain a slash, assume it's in the PATH.
          ProcessInfo.processInfo.environment["PATH"]!
            .split(separator: ":")
            .lazy
            .map({ "\($0)/\(capnp)" })
            .first(where: { FileManager.default.isExecutableFile(atPath: $0) })!
        }

      var arguments = [String](CommandLine.arguments.suffix(from: 2))
      arguments.append("--output=-")
      arguments.append("--import-path=\(URL.currentDirectory().path())")

      capnpProcess.executableURL = URL(filePath: capnpPath, directoryHint: .notDirectory)
      capnpProcess.arguments = arguments
      capnpProcess.standardOutput = outputPipe

      try! capnpProcess.run()

      while let data = try outputPipe.fileHandleForReading.read(upToCount: chunkSize) {
        guard let result = try messageDecoder.push(data) else { continue }
        guard result.readBytes == data.count,
          try outputPipe.fileHandleForReading.read(upToCount: 1) == nil
        else {
          fputs("more than one message given\n", stderr)
          exit(1)
        }
        return result.message
      }

      capnpProcess.waitUntilExit()

      if capnpProcess.terminationStatus != 0 {
        fputs(
          "\(capnp) failed with exit code \(capnpProcess.terminationStatus)\n",
          stderr
        )
        exit(1)
      }

      fputs("failed to decode message from arguments\n", stderr)
      exit(1)
    }
  #endif

  var chunk = Data(capacity: chunkSize)
  var message: Message?

  while chunk.withUnsafeMutableBytes({ chunkBufferRaw in
    let chunkBuffer = chunkBufferRaw.bindMemory(to: UInt8.self)
    let chunkPointer = chunkBuffer.baseAddress!
    let readBytes = read(STDIN_FILENO, chunkPointer, chunkSize)

    if readBytes < 0 {
      fputs("failed to read from stdin: \(String(cString: strerror(errno)))\n", stderr)
      exit(1)
    }
    if readBytes == 0 {
      return false
    }

    guard
      let result = try! messageDecoder.push(
        UnsafeRawBufferPointer(start: chunkPointer, count: readBytes)
      )
    else {
      return true
    }

    guard result.readBytes == readBytes, read(STDIN_FILENO, chunkPointer, 1) == 0 else {
      fputs("more than one message given\n", stderr)
      exit(1)
    }

    message = result.message
    return false
  }) {}

  guard let message else {
    fputs("failed to decode message from stdin\n", stderr)
    exit(1)
  }

  return message
}

/// Writes all of `contents` to the file specified by `fileName`. Returns `false` on error, in which
/// case an error message will have been printed to `stderr`.
func write(to fileName: String, contents: String) -> Bool {
  var contents = contents
  var file: Int32 = -1

  fileName.withCString { fileNamePtr in
    file = open(
      fileNamePtr,
      O_WRONLY | O_CREAT | O_TRUNC,
      S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH
    )
  }

  if file < 0 {
    fputs("failed to open file \(fileName): \(String(cString: strerror(errno)))\n", stderr)
    return false
  }

  defer { close(file) }

  return contents.withUTF8 { contentsBuffer in
    var writtenBytes = 0

    while writtenBytes < contentsBuffer.count {
      let bytesToWrite = contentsBuffer.count - writtenBytes
      let result = write(file, contentsBuffer.baseAddress! + writtenBytes, bytesToWrite)

      if result < 0 {
        fputs(
          "failed to write to file \(fileName): \(String(cString: strerror(errno)))\n",
          stderr
        )
        return false
      }

      writtenBytes += result
    }

    return true
  }
}

/// Returns the map from file ID to module name parsed from the environment variable
/// `CAPNPC_SWIFT_MODULES`.
func envModuleMap() -> [UInt64: Substring] {
  let varName = "CAPNPC_SWIFT_MODULES"

  guard let moduleNames = ProcessInfo.processInfo.environment[varName] else {
    return [:]
  }

  #if os(Windows)
    let separator = ";"
  #else
    let separator = ":"
  #endif
  let pairs = moduleNames.split(separator: separator, omittingEmptySubsequences: true)
  var result: [UInt64: Substring] = [:]

  for pair in pairs {
    let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)

    guard parts.count == 2,
      parts[0].starts(with: "0x"),
      parts[1].contains(/^\w+$/),
      let id = UInt64(parts[0].dropFirst(2), radix: 16)
    else {
      fputs("ignoring invalid variable format for \(varName): \(pair)", stderr)
      continue
    }

    result[id] = parts[1]
  }

  return result
}

// spell-checker: ignore errno fputs getenv strerror
// spell-checker: ignoreRegExp [OS]_\w+
