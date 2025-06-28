import Foundation
import PackagePlugin

@main
struct CapnProtoPlugin: BuildToolPlugin {
  func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
    guard let target = target as? SwiftSourceModuleTarget else {
      Diagnostics.error("Target is not a Swift source module")
      return []
    }

    let capnpcSwiftUrl = try context.tool(named: "capnpc-swift").url.path(percentEncoded: false)
    // If there is no dependency on `capnp-swift`, then we _are_ `capnp-swift`, and use `context.package`.
    let capnpSwiftDirUrl =
      context.package.dependencies.first(where: { $0.package.id == "capnp-swift" })?.package
      .directoryURL ?? context.package.directoryURL
    let capnpSwiftDir = capnpSwiftDirUrl.path(percentEncoded: false)

    guard let capnpUrl = findCapnpInPath() else {
      Diagnostics.error("Cannot find 'capnp' in PATH")
      return []
    }
    let outputDir = context.pluginWorkDirectoryURL.appending(
      component: "GeneratedSources",
      directoryHint: .isDirectory
    )

    var inputFiles: [URL] = []
    var outputFiles: [URL] = []
    var arguments: [String] = [
      "compile",
      "--output=\(capnpcSwiftUrl):\(outputDir.path(percentEncoded: false))",
      "--src-prefix=\(target.directoryURL.path(percentEncoded: false))",
      // Set `--import-path` to import `/swift.capnp`.
      "--import-path=\(capnpSwiftDir)",
    ]

    for file in target.sourceFiles(withSuffix: ".capnp") {
      guard let pathRelativeToSources = file.url.nonEscapingRelativePath(to: target.directoryURL)
      else {
        Diagnostics.error("Source file \(file.url) escapes source directory \(target.directoryURL)")
        return []
      }
      let outputPath = outputDir.appending(path: pathRelativeToSources).appendingPathExtension(
        "swift"
      )

      inputFiles.append(file.url)
      outputFiles.append(outputPath)
      arguments.append(file.url.path(percentEncoded: false))
    }

    guard !inputFiles.isEmpty else {
      return []
    }

    return [
      .buildCommand(
        displayName: "Running CapnProto",
        executable: capnpUrl,
        arguments: arguments,
        inputFiles: inputFiles,
        outputFiles: outputFiles
      )
    ]
  }
}

/// Returns the full path of `capnp` found in `PATH`.
func findCapnpInPath() -> URL? {
  let path = ProcessInfo.processInfo.environment["PATH"]!

  for dir in path.split(separator: ":") {
    let fullPath = "\(dir)/capnp"

    if FileManager.default.isExecutableFile(atPath: fullPath) {
      return URL(fileURLWithPath: fullPath, isDirectory: false)
    }
  }

  return nil
}

extension URL {
  func nonEscapingRelativePath(to base: URL) -> String? {
    var resolvedSelf = standardizedFileURL.resolvingSymlinksInPath().pathComponents
    let resolvedBase = base.standardizedFileURL.resolvingSymlinksInPath().pathComponents

    guard
      resolvedSelf.count > resolvedBase.count,
      resolvedSelf[..<resolvedBase.count] == resolvedBase[...]
    else {
      return nil
    }

    resolvedSelf.removeFirst(resolvedBase.count)

    return resolvedSelf.joined(separator: "/")
  }
}
