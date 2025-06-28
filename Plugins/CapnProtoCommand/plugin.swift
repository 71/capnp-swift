import Foundation
import PackagePlugin

@main
struct CapnProtoCommand: CommandPlugin {
  func performCommand(context: PluginContext, arguments: [String]) async throws {
    let capnpcSwiftTool = try context.tool(named: "capnpc-swift").url.path(percentEncoded: false)
    var outputDirectorySuffix = ""

    switch arguments.count {
    case 0: break
    case 1: outputDirectorySuffix = ":\(arguments[0])"
    default:
      Diagnostics.error("Usage: swift package print-capnp-compile [output-directory]")
      return
    }

    // If there is no dependency on `capnp-swift`, then we _are_ `capnp-swift`, and use `context.package`.
    let capnpSwiftDirUrl =
      context.package.dependencies.first(where: { $0.package.id == "capnp-swift" })?.package
      .directoryURL ?? context.package.directoryURL
    let capnpSwiftDir = capnpSwiftDirUrl.path(percentEncoded: false)

    print(
      "--output=\(capnpcSwiftTool)\(outputDirectorySuffix) --import-path=\(capnpSwiftDir)"
    )
  }
}
