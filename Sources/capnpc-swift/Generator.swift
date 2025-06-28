import CapnProto
import CapnProtoSchema
import Foundation

public enum GenerateError: Error, CustomStringConvertible {
  case assertionFailed(path: String, message: String)
  case nodeNotFound(path: String, id: UInt64)
  case identifierIsNotUtf8(path: String, escaped: String)
  case missingValue(path: String, fieldName: String)
  case unsupported(path: String, feature: String)
  case invalidSchema(PointerError)

  public var description: String {
    switch self {
    case .assertionFailed(let path, let message):
      return "Assertion failed in \(path): \(message)."
    case .nodeNotFound(let path, let id):
      return "Node with ID \(id) not found in \(path)."
    case .identifierIsNotUtf8(let path, let escaped):
      return "Identifier in \(path) is not valid UTF-8: \"\(escaped)\"."
    case .missingValue(let path, let fieldName):
      return "Missing value for \(fieldName) in \(path)."
    case .unsupported(let path, let feature):
      return "Unsupported feature in \(path): \(feature)."
    case .invalidSchema(let error):
      return "Input schema is invalid: \(error)."
    }
  }
}

public func generateFiles(
  for request: CodeGeneratorRequest,
  fileIdToModuleMap: [UInt64: Substring] = [:],
  warnWith: (String) -> Void = { _ in }
) throws(GenerateError) -> [(relativePath: String, contents: String)] {
  let requestedFiles = try mapError(request.requestedFiles())
  guard !requestedFiles.isEmpty else { return [] }
  let nodes = try mapError(request.nodes())

  return try withoutActuallyEscaping(warnWith) { (onWarning) throws(GenerateError) in
    var generator = try Generator(nodes, addWarning: onWarning)
    var generated: [(String, String)] = []

    if let sourceInfo = try? request.sourceInfo() {
      for sourceInfo in sourceInfo {
        generator.sourceInfo[sourceInfo.id] = sourceInfo
      }
    }

    generated.reserveCapacity(requestedFiles.count)

    for file in requestedFiles {
      guard var filePath = try mapError(file.filename().toString()) else {
        throw .missingValue(path: "requestedFiles", fieldName: "filename")
      }
      filePath.append(".swift")

      try generator.file(file, fileIdToModuleMap: fileIdToModuleMap)

      generated.append((filePath, generator.finish()))
    }

    return generated
  }
}

private struct Generator: ~Copyable {
  var mainSource: String = ""
  var extensionsSource: String = ""

  var mainSourceIndent: String = ""
  var pathSegments: [Substring] = []
  var currentScopeId: UInt64 = 0

  var currentFileName: String = ""
  var currentFileId: UInt64 = 0
  var currentModuleName: Substring = ""

  /// A map from type name to its depth in the current scope. That is, if the type is defined at
  /// the top-level, it has depth 0, but if it is defined inside a struct, it has depth 1.
  var typesInScope: [Substring: UInt16] = [:]

  /// A map from module name to top-level symbols in that module that need to be aliased at the
  /// root of the file.
  var importedModuleToTopLevelAliases: [Substring: Set<Substring>] = [:]

  var errorPath: String {
    pathSegments.isEmpty
      ? currentFileName : "\(currentFileName):\(pathSegments.joined(separator: "."))"
  }
  var addWarning: (String) -> Void
  var sourceInfo: [UInt64: Node.SourceInfo] = [:]

  /// Map from imported file ID to Swift module name.
  var imports: [UInt64: Substring] = [:]

  let nodes: List<Node>
  var nodeMap: [UInt64: Node] = [:]

  var path: String { pathSegments.joined(separator: ".") }

  /// Whether we started writing extensions for the current type.
  var writingExtensionsForType: Bool = false

  init(_ nodes: List<Node>, addWarning: @escaping (String) -> Void) throws(GenerateError) {
    self.nodes = nodes
    self.addWarning = addWarning

    for node in nodes {
      nodeMap[node.id] = node
    }
  }

  mutating func finish() -> String {
    var header = """
      // Automatically generated from \(currentFileName) @\(id(currentFileId)).
      // See https://github.com/71/capnp-swift for more information.
      //
      // swift-format-ignore-file
      """

    let allImports = Set(imports.values)
    let sortedImports = allImports.sorted()

    for import_ in sortedImports where import_ != currentModuleName {
      header.append("\nimport \(import_)")
    }
    header.append("\n\n")

    for (moduleName, names) in importedModuleToTopLevelAliases.sorted(by: { $0.key < $1.key }) {
      // `typealias`es must be public.
      header.append("public struct \(moduleName)$ {\n")
      for name in names.sorted() {
        header.append("  public typealias \(name) = \(moduleName).\(name)\n")
      }
      header.append("}\n\n")
    }
    importedModuleToTopLevelAliases.removeAll()

    if !extensionsSource.isEmpty {
      line("// \(String(repeating: Character("-"), count: 77))")
      line("// MARK: Extensions")
      line()
    }

    return header + mainSource + extensionsSource
  }
}

extension Generator {
  /// Appends a line of code to the main source.
  mutating func line(_ text: String = "") {
    if !text.isEmpty {
      mainSource.append(mainSourceIndent)
      mainSource.append(text)
    }
    mainSource.append(Character("\n"))
  }

  /// Appends a line of code to the extensions source.
  mutating func extensionLine(_ text: String = "") {
    extensionsSource.append(text)
    extensionsSource.append(Character("\n"))
  }

  mutating func doc(_ text: String) {
    let lines = text.trimmingCharacters(in: .whitespacesAndNewlines).split(
      separator: "\n",
      omittingEmptySubsequences: false
    )

    for line in lines {
      mainSource.append(mainSourceIndent)

      if line.isEmpty {
        mainSource.append("///\n")
      } else {
        mainSource.append("/// \(line)\n")
      }
    }
  }

  func node(_ id: UInt64) throws(GenerateError) -> Node {
    guard let node = nodeMap[id] else {
      throw .nodeNotFound(path: errorPath, id: id)
    }

    return node
  }

  /// Increases the current indent level.
  mutating func indent() { mainSourceIndent.append("  ") }
  /// Decreases the current indent level.
  mutating func dedent() { mainSourceIndent.removeLast(2) }

  /// If `warnings` was specified, appends `err.description` to it. Otherwise, rethrows `err`.
  mutating func warn(_ err: GenerateError) throws(GenerateError) {
    addWarning(err.description)
  }

  /// Increases the indentation
  mutating func scope(id: UInt64? = nil, named name: Substring? = nil) -> some ~Copyable {
    struct Scope: ~Copyable {
      let generator: UnsafeMutablePointer<Generator>
      let hasName: Bool
      let previousId: UInt64

      deinit {
        generator.pointee.dedent()
        generator.pointee.currentScopeId = previousId
        if hasName {
          generator.pointee.pathSegments.removeLast()
        }
      }
    }

    indent()
    if let name {
      pathSegments.append(name)
    }
    let previousId =
      if let id { exchange(&currentScopeId, with: id) } else {
        currentScopeId
      }

    return withUnsafeMutablePointer(to: &self) {
      Scope(generator: $0, hasName: name != nil, previousId: previousId)
    }
  }

  /// Converts a `Text` to a string, throwing an error if it is not valid.
  func toString(_ text: Text) throws(GenerateError) -> String {
    if let string = text.toString() {
      string
    } else {
      throw .identifierIsNotUtf8(
        path: errorPath,
        escaped: .init(cString: text.bytes.bytes().baseAddress!)
      )
    }
  }

  func name(of node: Node) throws(GenerateError) -> Substring {
    let displayNameText = try mapError(try node.displayName())
    let fullName = try toString(displayNameText)

    return fullName[
      fullName.index(fullName.startIndex, offsetBy: Int(node.displayNamePrefixLength))...
    ]
  }
}

extension Generator {
  mutating func file(
    _ file: CodeGeneratorRequest.RequestedFile,
    fileIdToModuleMap: [UInt64: Substring]
  ) throws(GenerateError) {
    imports.removeAll()
    imports[swiftCapnpId] = "CapnProto"

    for (importedFileId, moduleName) in fileIdToModuleMap {
      imports[importedFileId] = moduleName
    }

    mainSource = ""
    extensionsSource = ""
    currentFileName = (try? file.filename())?.toString() ?? "<unknown>"
    currentFileId = file.id
    currentModuleName = try moduleName(ofFileWithId: file.id)
    currentScopeId = file.id

    (try nestedNodes(of: node(file.id)))(&self)
  }

  mutating func nestedNodes(of node: Node) throws(GenerateError) -> (inout Self) -> Void {
    let currentDepth = UInt16(pathSegments.count)
    let nestedNodes = try mapError(try node.nestedNodes())

    // Compute names in scope.
    var namesInScope: [Substring] = nestedNodes.compactMap { nestedNode in
      guard let nestedNode = nodeMap[nestedNode.id],
        let nestedNodeName = try? name(of: nestedNode)
      else {
        return nil
      }

      return nestedNodeName
    }

    // Add generated names to the scope names.
    if let struct_ = node.struct, let fields = try? struct_.fields() {
      for field in fields {
        guard field.whichDiscriminant == .group,
          let groupName = try? field.name().toString()
        else { continue }

        namesInScope.append("\(capitalized: groupName)")
      }
    }

    // Add names to the current scope.
    var prevNodeDepths = [(Substring, UInt16)]()

    prevNodeDepths.reserveCapacity(nestedNodes.count)

    for name in namesInScope {
      prevNodeDepths.append((name, typesInScope[name] ?? .max))

      typesInScope[name] = currentDepth
    }

    // Process nested nodes.
    for nestedNode in nestedNodes {
      try self.node(self.node(nestedNode.id))
    }

    return { (self: inout Self) in
      // Remove nested nodes from the current scope.
      for (name, prevNodeDepth) in prevNodeDepths {
        if prevNodeDepth == .max {
          self.typesInScope.removeValue(forKey: name)
        } else {
          self.typesInScope[name] = prevNodeDepth
        }
      }
    }
  }

  mutating func node(_ node: Node) throws(GenerateError) {
    if let docComment = try? sourceInfo[node.id]?.docComment(), !docComment.bytes.isEmpty {
      doc(try toString(docComment))
    }

    switch try mapError(node.which()) {
    case .annotation(_):
      break
    case .const(let const):
      try self.const(node, const)
    case .enum(let enum_):
      try self.enum(node, enum_)
    case .struct(let struct_):
      try self.struct(node, struct_)
    case .interface(_):
      try warn(.unsupported(path: errorPath, feature: "interfaces"))
    case .file:
      try warn(.assertionFailed(path: errorPath, message: "unexpected nested file"))
    case nil:
      try warn(.missingValue(path: errorPath, fieldName: "which"))
    }
  }

  mutating func const(_ node: Node, _ const: Node.Const) throws(GenerateError) {
    let name = try name(of: node)
    let type = try mapError(try const.type())
    let value = try mapError(try const.value())

    if let docComment = try? sourceInfo[node.id]?.docComment(), !docComment.bytes.isEmpty {
      doc(try toString(docComment))
    }

    let isFrozen =
      switch type.whichDiscriminant.orDefault {
      case .data, .list, .struct, .text:
        true
      default:
        false
      }
    let (typePrefix, typeSuffix, exprPrefix, exprSuffix) =
      isFrozen ? ("CapnProto.Frozen<", ">", ".init { ", " }") : ("", "", "", "")

    try line(
      "public static let \(ident(name)): \(typePrefix)\(type, in: &self)\(typeSuffix) =  // \(id(node.id))"
    )

    try withExtendedLifetime(scope()) { () throws(GenerateError) in
      try line("\(exprPrefix)\(value, of: type, in: self)\(exprSuffix)")
    }

    line()
  }

  mutating func `enum`(_ node: Node, _ enum_: Node.Enum) throws(GenerateError) {
    let name = try name(of: node)
    let enumerants = try mapError(try enum_.enumerants())
    let pathPrefix =
      pathSegments.isEmpty
      ? "" : pathSegments.joined(separator: ".") + "."

    line("public enum \(typeIdent(name)): UInt16, CapnProto.Enum {")
    extensionLine("extension CapnProto.EnumValue<\(pathPrefix)\(typeIdent(name))> {")
    try withExtendedLifetime(scope(id: node.id, named: name)) { () throws(GenerateError) in
      let enumerantNames = try enumerants.map { (enumerant) throws(GenerateError) in
        ident(try toString(mapError(enumerant.name())))
      }

      line("public static let id: UInt64 = \(id(node.id))")
      line("public static let defaultValue: Self = .\(enumerantNames.first!)")
      line("public static let maxValue: Self = .\(enumerantNames.last!)")
      line()

      let sourceInfo = try? sourceInfo[node.id]?.members()

      for (value, enumerantName) in enumerantNames.enumerated() {
        if let docComment = try? sourceInfo?.read(at: value).docComment(),
          !docComment.bytes.isEmpty
        {
          doc(try toString(docComment))
        }

        line("case \(enumerantName) = \(value)")
        // Note: we cannot be explicit and prefix the `enumerantName` with the `path` here,
        // as if the enum is named "Type" the compiler will be unable to resolve enum cases
        // (even if "Type" is between backticks).
        extensionLine(
          "  public static let \(enumerantName): Self = .init(.\(enumerantName))"
        )
      }
    }
    line("}")
    extensionLine("}")
    line()
    extensionLine()
  }

  mutating func `struct`(_ node: Node, _ struct_: Node.Struct, name: Substring? = nil)
    throws(GenerateError)
  {
    let name =
      if let name {
        name
      } else {
        try self.name(of: node)
      }
    let fields = try mapError(try struct_.fields())
    let namedFields = try fields.map { (field) throws(GenerateError) in
      (
        try toString(mapError(field.name())), field
      )
    }

    line("public struct \(typeIdent(name)): CapnProto.Struct {")
    try withExtendedLifetime(scope(id: node.id, named: name)) { () throws(GenerateError) in
      let structSize =
        "safeDataBytes: \(struct_.dataWordCount * 8), pointers: \(struct_.pointerCount)"

      line("public static let id: UInt64 = \(id(node.id))")
      line("public static let size: CapnProto.StructSize = .init(\(structSize))")

      if struct_.discriminantCount > 0 && struct_.discriminantOffset == 0 {
        line("public static let firstFieldSize: CapnProto.ListElementSize? = .twoBytes")
      } else {
        let firstFieldSizeStr =
          namedFields.compactMap { (_, field) -> String? in
            guard
              field.discriminantValue == 0xffff,
              let slot = field.slot,
              let type = try? slot.type().whichDiscriminant.orNil
            else { return nil }

            return switch type {
            case .bool:
              nil  // A list of voids or bools cannot become a struct.

            case .void: ".zero"
            case .int8, .uint8: ".oneByte"
            case .int16, .uint16, .enum: ".twoBytes"
            case .int32, .uint32, .float32: ".fourBytes"
            case .int64, .uint64, .float64: ".eightBytes"
            case .text, .data, .list, .anyPointer, .struct, .interface: ".pointer"
            }
          }.first ?? "nil"

        line(
          "public static let firstFieldSize: CapnProto.ListElementSize? = \(firstFieldSizeStr)"
        )
      }
      line()

      let clearScope = try nestedNodes(of: node)
      defer { clearScope(&self) }

      var groupNames: [String] = []

      for (fieldName, field) in namedFields {
        guard let group = field.group else {
          continue
        }

        var groupName = fieldName
        if let first = groupName.first {
          groupName.replaceSubrange(
            groupName.startIndex..<groupName.index(after: groupName.startIndex),
            with: first.uppercased()
          )
        }

        let groupNode = try self.node(group.typeId)
        let groupStruct = try groupNode.struct.orMissing(
          in: self,
          fieldName: "group.struct"
        )

        line("/// Generated for group `\(fieldName)`.")

        try self.struct(groupNode, groupStruct, name: groupName[...])

        groupNames.append(groupName)
      }

      var groupNamesIterator = groupNames.makeIterator()

      line("public var struct$: CapnProto.StructPointer")
      line()
      line("public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }")
      line()

      let union: UnionInformation? =
        if struct_.discriminantCount == 0 {
          .none
        } else {
          .some(
            try .init(
              discriminantOffset: struct_.discriminantOffset,
              fields: namedFields.filter { $0.1.discriminantValue != 0xffff },
              dataWords: UInt32(struct_.dataWordCount),
              in: self
            )
          )
        }

      if let union {
        try which(union)
      }

      let sourceInfo = try mapError(try sourceInfo[node.id]?.members())

      for (index, (fieldName, field)) in namedFields.enumerated() {
        let discriminantValue =
          field.discriminantValue == 0xffff
          ? nil : field.discriminantValue

        let docComment = try? sourceInfo?.read(at: index).docComment()

        if let docComment, !docComment.bytes.isEmpty {
          doc(try toString(docComment))
        }

        if discriminantValue != nil {
          if docComment?.bytes.isEmpty == false { line("///") }

          line("/// Part of a union.")
        }

        switch try mapError(field.which()).orMissing(in: self, fieldName: "field.which") {
        case .slot(let slot):
          try slotField(
            slot,
            fieldName: fieldName,
            discriminantValue: discriminantValue,
            union: union
          )
        case .group(let group):
          let groupNode = try self.node(group.typeId)

          try groupField(
            group: groupNode,
            groupName: groupNamesIterator.next()!,
            fieldName: fieldName,
            discriminantValue: discriminantValue,
            union: union
          )
        }

        line()
      }

      endExtensionForCurrentType()

      // Remove the last empty line we added above.
      mainSource.removeLast()
    }
    line("}")
    line()
  }

  mutating func which(_ union: UnionInformation) throws(GenerateError) {
    line("public enum Which {")
    try withExtendedLifetime(scope()) { () throws(GenerateError) in
      line("public enum Discriminant: UInt16, CapnProto.EnumOrDiscriminant {")
      line("  public static let defaultValue: Discriminant = .\(union.fields.first!.name)")
      line("  public static let maxValue: Discriminant = .\(union.fields.last!.name)")
      line()
      extensionLine("extension CapnProto.EnumValue<\(path).Which.Discriminant> {")
      for (fieldName, field) in union.fields {
        line("  case \(ident(fieldName)) = \(field.discriminantValue)")
        extensionLine(
          "  public static let \(ident(fieldName)): Self = .init(\(field.discriminantValue))"
        )
      }
      line("}")
      line()
      extensionLine("}")
      extensionLine()

      for (fieldName, field) in union.fields {
        let fieldType: String =
          switch try mapError(field.slot?.type())?.whichDiscriminant.orNil {
          case nil: "(\(capitalized: fieldName))"  // Group.
          case .void: ""
          case .anyPointer: "(CapnProto.AnyPointer?)"
          default: try "(\(try! field.slot!.type(), in: &self))"
          }

        line("case \(ident(fieldName))\(fieldType)")
      }
    }
    line("}")
    line()

    line("public var whichDiscriminant: CapnProto.EnumValue<Which.Discriminant> {")
    line(
      "  struct$.readEnum(atByte: \(union.discriminantOffset * 2), defaultValue: .\(union.fields.first!.name))"
    )
    line("}")
    line()

    // Make `which()` fallible if any of the union fields is fallible. We could alternatively
    // always make it fallible to avoid signature changes in the future if a new field is added,
    // but we wouldn't gain much from it: in any case the callers will need to be updated as the
    // result of `which()` will now have more cases.
    let isFallible = union.fields.contains { (_, field) in
      deserializationIsFallible(field: field)
    }
    let throwsClause = isFallible ? " throws(CapnProto.PointerError)" : ""

    line("public func which()\(throwsClause) -> Which? {")
    try withExtendedLifetime(scope()) { () throws(GenerateError) in
      line("switch whichDiscriminant.rawValue {")
      for (fieldName, field) in union.fields {
        let arg: String =
          if let slot = field.slot {
            (try? slot.type())?.whichDiscriminant == .void
              ? "" : try "(\(read: slot, named: fieldName, in: &self))"
          } else {
            "(.init(struct$))"  // Group.
          }

        line("case \(field.discriminantValue): .\(fieldName)\(arg)")
      }
      line("default: nil")
      line("}")
    }
    line("}")
    line()
  }

  mutating func slotField(
    _ slot: Field.Slot,
    fieldName: String,
    discriminantValue: UInt16?,
    union: UnionInformation?
  ) throws(GenerateError) {
    let type = try mapError(try slot.type())
    let defaultValue = try mapError(try slot.defaultValue())
    let defaultValueExpr =
      slot.hadExplicitDefault ? try "\(defaultValue, of: type, in: self)" : nil
    let typeString = try "\(type, in: &self)"

    let typeDiscriminant = try type.whichDiscriminant.orNil.orMissing(
      in: self,
      fieldName: "field.slot.type.which"
    )

    switch typeDiscriminant {
    case .void:
      if let discriminantValue {
        line("public var \(ident(fieldName)): CapnProto.VoidValue? {")
        line("  whichDiscriminant.rawValue == \(discriminantValue) ? .init() : nil")
        line("}")
        line()
        line("public func set\(capitalized: fieldName)() {")
        line("  _ = \(union!.writeExpr(discriminantValue: discriminantValue))")
        line("}")
      } else {
        line("public var \(ident(fieldName)): CapnProto.VoidValue {")
        line("  get { .init() }")
        line("  nonmutating set { _ = newValue }")
        line("}")
      }

    case .bool, .int8, .uint8, .int16, .uint16, .int32, .uint32,
      .float32, .int64, .uint64, .float64, .enum, .interface:
      if let discriminantValue {
        line("public var \(ident(fieldName)): \(typeString)? {")
        try line(
          "  whichDiscriminant.rawValue == \(discriminantValue) ? \(read: slot, named: fieldName, defaultValue: defaultValueExpr, in: &self) : nil"
        )
        line("}")
        line()
        line("public func set\(capitalized: fieldName)(_ newValue: \(typeString)) {")
        line("  if \(union!.writeExpr(discriminantValue: discriminantValue)) {")
        try line("    \(write: slot, defaultValue: defaultValueExpr, in: &self)")
        line("  }")
        line("}")
      } else {
        line("public var \(ident(fieldName)): \(typeString) {")
        try line(
          "  get { \(read: slot, named: fieldName, defaultValue: defaultValueExpr, in: &self) }"
        )
        try line("  nonmutating set { \(write: slot, defaultValue: defaultValueExpr, in: &self) }")
        line("}")
      }

    case .anyPointer:
      // For now we don't support writing `AnyPointer`s, so this is read-only.
      var typeSuffix = "?"

      if let defaultValueExpr {
        startExtensionForCurrentType()
        extensionLine(
          "  private static let default\(capitalized: fieldName): CapnProto.Frozen<AnyPointer> = .init {"
        )
        extensionLine("    \(defaultValueExpr)")
        extensionLine("  }")

        typeSuffix = ""
      }

      if let discriminantValue {
        line("public var \(ident(fieldName)): CapnProto.AnyPointer? {")
        try line(
          "  whichDiscriminant.rawValue == \(discriminantValue) ? \(read: slot, named: fieldName, defaultValue: defaultValueExpr, in: &self) : nil"
        )
      } else {
        line("public var \(ident(fieldName)): CapnProto.AnyPointer\(typeSuffix) {")
        try line("  \(read: slot, named: fieldName, defaultValue: defaultValueExpr, in: &self)")
      }
      line("}")

    case .data, .list, .struct, .text:
      if let defaultValueExpr {
        startExtensionForCurrentType()
        extensionLine(
          "  private static let default\(capitalized: fieldName): CapnProto.Frozen<\(typeString)> = .init {"
        )
        extensionLine("    \(defaultValueExpr)")
        extensionLine("  }")
      }

      if let discriminantValue {
        line(
          "public func \(ident(fieldName))() throws(CapnProto.PointerError) -> \(typeString)? {"
        )
        try line(
          "  whichDiscriminant.rawValue == \(discriminantValue) ? \(read: slot, named: fieldName, defaultValue: defaultValueExpr, in: &self) : nil"
        )
        line("}")
      } else {
        line(
          "public func \(ident(fieldName))() throws(CapnProto.PointerError) -> \(typeString) {"
        )
        try line("  \(read: slot, named: fieldName, defaultValue: defaultValueExpr, in: &self)")
        line("}")
      }

      let (prefix, suffix) =
        if let discriminantValue {
          ("\(union!.writeExpr(discriminantValue: discriminantValue)) ? ", " : nil")
        } else {
          ("", "")
        }

      let signature =
        switch typeDiscriminant {
        case .data, .list: "init\(capitalized: fieldName)(count: Int)"
        case .text: "set\(capitalized: fieldName)(_ text: Substring)"
        case .struct: "init\(capitalized: fieldName)()"
        default: fatalError()
        }

      line()
      line("public func \(signature) -> \(typeString)? {")
      try line("  \(prefix)\(write: slot, defaultValue: defaultValueExpr, in: &self)\(suffix)")
      line("}")
    }
  }

  mutating func groupField(
    group: Node,
    groupName: String,
    fieldName: String,
    discriminantValue: UInt16?,
    union: UnionInformation?
  )
    throws(GenerateError)
  {
    let (getter, opt) =
      if let discriminantValue {
        ("whichDiscriminant.rawValue == \(discriminantValue) ? .init(struct$) : nil", "?")
      } else {
        (".init(struct$)", "")
      }

    line("public var \(ident(fieldName)): \(groupName)\(opt) { \(getter) }")

    if let discriminantValue {
      line()
      line("public func init\(groupName)() -> \(groupName) {")
      try withExtendedLifetime(scope()) { () throws(GenerateError) in
        line("_ = \(union!.writeExpr(discriminantValue: discriminantValue))")

        // > Unions and groups need not occupy contiguous memory.
        //
        // So we must clear fields in the group individually.
        try clearGroupField(group)

        line("return .init(struct$)")
      }
      line("}")
    }
  }

  mutating func clearGroupField(_ group: Node) throws(GenerateError) {
    let fields = try mapError(try group.struct?.fields()).orMissing(
      in: self,
      fieldName: "group.struct.fields"
    )

    for field in fields {
      switch try mapError(field.which()).orMissing(in: self, fieldName: "field.which") {
      case .slot(let slot):
        try clearSlotField(slot)

      case .group(let group):
        let groupNode = try node(group.typeId)

        try clearGroupField(groupNode)
      }
    }
  }

  mutating func clearSlotField(_ slot: Field.Slot) throws(GenerateError) {
    switch try mapError(slot.type().which()).orMissing(in: self, fieldName: "slot.type.which") {
    case .void:
      break
    case .bool:
      line("_ = struct$.write(false, atBit: \(slot.offset))")
    case .int8, .uint8:
      line("_ = struct$.write(UInt8(0), atByte: \(slot.offset))")
    case .int16, .uint16, .enum:
      line("_ = struct$.write(UInt16(0), atByte: \(slot.offset * 2))")

    case .int32, .uint32, .float32:
      line("_ = struct$.write(UInt32(0), atByte: \(slot.offset * 4))")
    case .int64, .uint64, .float64, .text, .data, .list, .struct, .interface, .anyPointer:
      line("_ = struct$.write(UInt64(0), atByte: \(slot.offset * 8))")
    }
  }

  mutating func moduleName(ofFileWithId id: UInt64) throws(GenerateError) -> Substring {
    // Try to get the module name from the cache.
    if let name = imports[id] {
      return name
    }

    // Get the module name from the file annotation.
    let node = try self.node(id)

    for annotation in try mapError(node.annotations()) {
      guard annotation.id == swiftCapnpModuleAnnotationId else { continue }

      // Use the module name specified in the annotation.
      guard let moduleNameText = try mapError(annotation.value().text()) else {
        throw .missingValue(path: "$Swift.module", fieldName: "value.text")
      }

      let moduleName = Substring(try mapError(moduleNameText.toString()) ?? "")

      guard !moduleName.isEmpty else {
        throw .missingValue(path: "$Swift.module", fieldName: "value.text")
      }

      imports[id] = .init(moduleName)

      return moduleName
    }

    // Fall back to the file name.
    var moduleName = try mapError(node.displayName().toString()).orMissing(
      in: self,
      fieldName: "node.displayName"
    )
    moduleName.append(".swift")

    if let index = moduleName.lastIndex(of: "/") {
      moduleName.removeSubrange(moduleName.startIndex...index)
    }
    moduleName.removeLast(".swift".count)

    let moduleNameSubstring = Substring(moduleName)

    imports[id] = moduleNameSubstring

    return moduleNameSubstring
  }

  mutating func startExtensionForCurrentType() {
    if !writingExtensionsForType {
      writingExtensionsForType = true
      extensionsSource.append("extension \(path) {\n")
    }
  }

  mutating func endExtensionForCurrentType() {
    if writingExtensionsForType {
      writingExtensionsForType = false
      extensionsSource.append("}\n\n")
    }
  }
}

// -------------------------------------------------------------------------------------------------
// MARK: - String helpers

extension DefaultStringInterpolation {
  /// Appends a path from the current `generator` scope to the given `node`.
  fileprivate mutating func appendInterpolation(
    pathOf node: Node,
    in generator: inout Generator
  ) throws(GenerateError) {
    // Swift does not allow us to refer to the "global" namespace, like "global::" in C# or
    // "::" in C++: https://forums.swift.org/t/fixing-modules-that-contain-a-type-with-the-same-name/3025.
    // Therefore, we cannot simply make all paths absolute, as this could lead to conflicts
    // (if a type in scope has the same name as the module). We therefore try our best to make
    // paths relative (which will avoid some of these conflicts), and fall back to absolute
    // paths, hoping that this won't lead to conflicts for our users.

    // Compute the qualified path of the node.
    var nodePath: [Substring] = []
    var currentNode: Node = node

    while currentNode.scopeId != 0 {
      nodePath.append(try generator.name(of: currentNode))
      currentNode = try generator.node(currentNode.scopeId)
    }

    nodePath.reverse()

    guard currentNode.whichDiscriminant == .file else {
      throw .assertionFailed(path: "scopeId", message: "top-most node is not a file")
    }

    let nodeFileId = currentNode.id

    if nodeFileId != generator.currentFileId {
      // If the two nodes are defined in different files, use an absolute path.
      let nodeModuleName = try generator.moduleName(ofFileWithId: nodeFileId)
      let nodeModuleNameConflictsWithTypeNameInScope =
        generator.typesInScope[nodeModuleName[...]] != nil

      appendInterpolation(nodeModuleName)

      if nodeModuleNameConflictsWithTypeNameInScope {
        // We cannot refer to the other file by its module name, as it conflicts with a
        // type name in scope. We redefine it at the top of the file, and refer to that
        // alias here instead.
        generator.importedModuleToTopLevelAliases[nodeModuleName, default: []].insert(
          nodePath.first!
        )
        appendInterpolation("$")
      }

      for segment in nodePath {
        appendInterpolation(".")
        appendInterpolation(typeIdent(segment))
      }

      return
    }

    // If the two nodes are in the same file, we can try to use a relative path. Start by
    // trimming the common prefix of the two paths. Don't trim the last segment, as that's the
    // name of the node itself, which we may refer (e.g. if the referrer is a child of the
    // referred).
    var commonPrefixLength = 0

    while commonPrefixLength < generator.pathSegments.count
      && commonPrefixLength < nodePath.count - 1
    {
      let segment = nodePath[commonPrefixLength]

      guard segment == generator.pathSegments[commonPrefixLength] else {
        // That's the end of the common prefix.
        break
      }

      if let depth = generator.typesInScope[segment], depth > commonPrefixLength {
        // If the relative path starts with a name in scope, we cannot use it.
        break
      }

      commonPrefixLength += 1
    }

    if commonPrefixLength == 0, let pathStart = nodePath.first,
      generator.typesInScope[pathStart] ?? 0 > 0
    {
      // We're referring to a type at the root of the file, but which conflicts with a type
      // in scope.
      generator.importedModuleToTopLevelAliases[generator.currentModuleName[...], default: []]
        .insert(pathStart)
      appendInterpolation(generator.currentModuleName)
      appendInterpolation("$.")
    }

    // Write segments.
    var isFirst = true

    for segment in nodePath[commonPrefixLength...] {
      if isFirst {
        isFirst = false
      } else {
        appendInterpolation(".")
      }

      appendInterpolation(typeIdent(segment))
    }
  }

  fileprivate mutating func appendInterpolation(
    _ type: Type,
    in generator: inout Generator
  )
    throws(GenerateError)
  {
    switch try mapError(type.which()).orMissing(in: generator, fieldName: "type.which") {
    case .void:
      appendInterpolation("CapnProto.VoidValue")
    case .bool:
      appendInterpolation("Bool")
    case .int8:
      appendInterpolation("Int8")
    case .int16:
      appendInterpolation("Int16")
    case .int32:
      appendInterpolation("Int32")
    case .int64:
      appendInterpolation("Int64")
    case .uint8:
      appendInterpolation("UInt8")
    case .uint16:
      appendInterpolation("UInt16")
    case .uint32:
      appendInterpolation("UInt32")
    case .uint64:
      appendInterpolation("UInt64")
    case .float32:
      appendInterpolation("Float32")
    case .float64:
      appendInterpolation("Float64")

    case .text:
      appendInterpolation("CapnProto.Text")
    case .data:
      appendInterpolation("CapnProto.List<UInt8>")
    case .anyPointer(_):
      appendInterpolation("CapnProto.AnyPointer")

    case .list(let list):
      let elementType = try mapError(try list.elementType())
      try appendInterpolation("CapnProto.List<\(elementType, in: &generator)>")

    case .enum(let enumType):
      appendInterpolation("CapnProto.EnumValue<")
      try appendInterpolation(pathOf: generator.node(enumType.typeId), in: &generator)
      appendInterpolation(">")

    case .struct(let structType):
      try appendInterpolation(pathOf: generator.node(structType.typeId), in: &generator)

    case .interface(_):
      appendInterpolation("CapnProto.AnyCapability")
    }
  }

  fileprivate mutating func appendInterpolation(
    _ value: Value,
    of type: Type,
    in generator: borrowing Generator
  ) throws(GenerateError) {
    let which = try mapError(try value.which())

    switch try which.orMissing(in: generator, fieldName: "value.which") {
    case .void:
      appendInterpolation(".init()")
    case .bool(let bool):
      appendInterpolation(bool)
    case .int8(let int8):
      appendInterpolation(int8)
    case .int16(let int16):
      appendInterpolation(int16)
    case .int32(let int32):
      appendInterpolation(int32)
    case .int64(let int64):
      appendInterpolation(int64)
    case .uint8(let uint8):
      appendInterpolation(uint8)
    case .uint16(let uint16):
      appendInterpolation(uint16)
    case .uint32(let uint32):
      appendInterpolation(uint32)
    case .uint64(let uint64):
      appendInterpolation(uint64)
    case .float32(let float32):
      appendInterpolation("Float32(bitPattern: 0x\(String(float32.bitPattern, radix: 16)))")
    case .float64(let float64):
      appendInterpolation("Float64(bitPattern: 0x\(String(float64.bitPattern, radix: 16)))")

    case .enum(let enumValue):
      let enumId = try type.enum.orMissing(in: generator, fieldName: "value.enum.id").typeId
      let enumNode = try generator.node(enumId)
      let enum_ = try enumNode.enum.orMissing(in: generator, fieldName: "value.enum")
      let enumerant = try mapError(try enum_.enumerants().read(at: Int(enumValue)))
      let enumerantName = try generator.toString(try mapError(try enumerant.name()))

      appendInterpolation(".\(ident(enumerantName))")

    case .text(let text):
      let string = try generator.toString(text)

      appendInterpolation(".readOnly(\(string.debugDescription))")

    case .data(let data):
      appendInterpolation(primitiveListValue: data.list$)

    case .list(let listPointer):
      guard let list = try mapError(listPointer?.resolve()?.expectList()), !list.isEmpty else {
        appendInterpolation(".readOnly()")
        return
      }

      switch list.elementSize.rawValue {
      case .oneBit, .oneByte, .twoBytes, .fourBytes, .eightBytes:
        appendInterpolation(primitiveListValue: list)

      case .zero:
        appendInterpolation(
          ".init(unchecked: .init(data: .readOnly(words: []), elementSize: .zero, count: \(list.count)))"
        )

      case .pointer, .composite:
        let listCopy = try mapError(list.copy())

        assert(listCopy.data.message.segmentCount == 1)

        appendInterpolation(
          ".init(unchecked: .init(data: \(pointerFromWords: listCopy.data.message.firstSegment.buffer.advanced(by: 1)), elementSize: \(listCopy.elementSize), count: \(list.count)))"
        )
      }

    case .struct(let structPointer):
      guard let structCopy = try mapError(structPointer?.copy().resolve()?.expectStruct())
      else {
        appendInterpolation(".readOnly()")
        return
      }
      assert(structCopy.data.message.segmentCount == 1)

      appendInterpolation(
        ".init(.init(data: \(pointerFromWords: structCopy.data.message.firstSegment.buffer.advanced(by: 1)), size: \(structCopy.size)))"
      )

    case .interface:
      appendInterpolation("nil")

    case .anyPointer(let anyPointer):
      guard let copiedPointer = try mapError(anyPointer?.copy()) else {
        appendInterpolation(".init(unsafePointer: .readOnly())")
        return
      }

      assert(copiedPointer.unsafePointer.message.segmentCount == 1)

      appendInterpolation(
        ".init(unsafePointer: \(pointerFromWords: copiedPointer.unsafePointer.message.firstSegment.buffer))"
      )
    }
  }

  fileprivate mutating func appendInterpolation(primitiveListValue: ListPointer) {
    guard !primitiveListValue.isEmpty else {
      appendInterpolation(".readOnly()")
      return
    }

    appendInterpolation(".init(unchecked: .init(data: .readOnly(words: [")

    let bitsCount = UInt64(primitiveListValue.rawCount) * primitiveListValue.elementSize.bits
    let wordsCount = bitsCount / 64 + (bitsCount % 64 == 0 ? 0 : 1)
    let wordsList = ListPointer(
      data: primitiveListValue.data,
      elementSize: .eightBytes,
      count: UInt32(wordsCount)
    )
    let words = List<Word>(unchecked: wordsList)

    appendInterpolation("0x\(String(words[0], radix: 16))")

    for word in words.dropFirst() {
      appendInterpolation(", 0x\(String(word, radix: 16))")
    }

    appendInterpolation(
      "]), elementSize: \(primitiveListValue.elementSize), count: \(primitiveListValue.count)))"
    )
  }

  fileprivate mutating func appendInterpolation(pointerFromWords: UnsafeBufferPointer<Word>) {
    guard let firstWord = pointerFromWords.first else {
      appendInterpolation(".readOnly()")
      return
    }

    appendInterpolation(".readOnly(words: [0x\(String(firstWord, radix: 16))")

    for word in pointerFromWords[1...] {
      appendInterpolation(", 0x\(String(word, radix: 16))")
    }

    appendInterpolation("])")
  }

  fileprivate mutating func appendInterpolation(
    read slot: Field.Slot,
    named fieldName: String,
    defaultValue: String? = nil,
    in generator: inout Generator
  ) throws(GenerateError) {
    let type = try mapError(slot.type()).whichDiscriminant.orNil.orMissing(
      in: generator,
      fieldName: "field.slot.type.which"
    )
    let defaultArg =
      if let defaultValue { ", defaultValue: \(defaultValue)" } else { "" }

    switch type {
    case .void:
      appendLiteral(".init()")

    case .bool:
      appendLiteral("struct$.read(atBit: \(slot.offset)\(defaultArg))")

    case .int8, .uint8:
      appendLiteral("struct$.read(atByte: \(slot.offset)\(defaultArg))")
    case .int16, .uint16:
      appendLiteral("struct$.read(atByte: \(slot.offset * 2)\(defaultArg))")
    case .int32, .uint32, .float32:
      appendLiteral("struct$.read(atByte: \(slot.offset * 4)\(defaultArg))")
    case .int64, .uint64, .float64:
      appendLiteral("struct$.read(atByte: \(slot.offset * 8)\(defaultArg))")

    case .enum:
      appendLiteral("struct$.readEnum(atByte: \(slot.offset * 2)\(defaultArg))")

    case .anyPointer:
      let defaultSuffix =
        defaultValue != nil ? "?.orNil ?? Self.default\(capitalized: fieldName).value" : ""

      appendInterpolation("struct$.readAnyPointer(at: \(slot.offset))\(defaultSuffix)")

    case .interface:
      appendInterpolation("struct$.readAnyCapability(at: \(slot.offset))")

    case .data, .list, .struct, .text:
      let fnName =
        switch type {
        case .data, .list: "readList"
        case .struct: "readStruct"
        case .text: "readText"
        default: fatalError()
        }
      let defaultValue =
        if defaultValue != nil { "Self.default\(capitalized: fieldName).value" } else { ".init()" }

      appendInterpolation("try struct$.\(fnName)(at: \(slot.offset)) ?? \(defaultValue)")
    }
  }

  fileprivate mutating func appendInterpolation(
    write slot: Field.Slot,
    defaultValue: String? = nil,
    in generator: inout Generator
  ) throws(GenerateError) {
    let type = try mapError(slot.type()).whichDiscriminant.orNil.orMissing(
      in: generator,
      fieldName: "field.slot.type.which"
    )
    let defaultArg =
      if let defaultValue { ", defaultValue: \(defaultValue)" } else { "" }

    switch type {
    case .void:
      appendLiteral("_ = newValue")

    case .bool:
      appendInterpolation("_ = struct$.write(newValue, atBit: \(slot.offset)\(defaultArg))")

    case .int8, .uint8:
      appendInterpolation("_ = struct$.write(newValue, atByte: \(slot.offset)\(defaultArg))")
    case .int16, .uint16:
      appendInterpolation("_ = struct$.write(newValue, atByte: \(slot.offset * 2)\(defaultArg))")
    case .int32, .uint32, .float32:
      appendInterpolation("_ = struct$.write(newValue, atByte: \(slot.offset * 4)\(defaultArg))")
    case .int64, .uint64, .float64:
      appendInterpolation("_ = struct$.write(newValue, atByte: \(slot.offset * 8)\(defaultArg))")

    case .enum:
      appendInterpolation(
        "_ = struct$.writeEnum(newValue, atByte: \(slot.offset * 2)\(defaultArg))"
      )

    case .anyPointer:
      fatalError("cannot generate write for AnyPointer field")

    case .interface:
      appendInterpolation("_ = struct$.writeAnyCapability(newValue, at: \(slot.offset))")

    case .text:
      appendInterpolation("struct$.writeText(text, at: \(slot.offset))")

    case .data, .list:
      appendInterpolation("struct$.initList(at: \(slot.offset), count: count)")

    case .struct:
      appendInterpolation("struct$.initStruct(at: \(slot.offset))")
    }
  }

  fileprivate mutating func appendInterpolation(capitalized text: String) {
    guard let first = text.first else { return }

    appendInterpolation(first.uppercased())
    appendInterpolation(text[text.index(after: text.startIndex)...])
  }

  fileprivate mutating func appendInterpolation(_ size: ListElementSize) {
    switch size {
    case .zero:
      appendInterpolation(".zero")
    case .oneBit:
      appendInterpolation(".oneBit")
    case .oneByte:
      appendInterpolation(".oneByte")
    case .twoBytes:
      appendInterpolation(".twoBytes")
    case .fourBytes:
      appendInterpolation(".fourBytes")
    case .eightBytes:
      appendInterpolation(".eightBytes")
    case .pointer:
      appendInterpolation(".pointer")
    case .composite(let size):
      appendInterpolation(".composite(\(size))")
    }
  }

  fileprivate mutating func appendInterpolation(_ size: StructSize) {
    switch (size.dataBytes, size.pointers) {
    case (0, 0):
      appendInterpolation(".zero")
    case (0, let pointers):
      appendInterpolation(".init(pointers: \(pointers))")
    case (let dataBytes, 0):
      appendInterpolation(".init(dataBytes: \(dataBytes))")
    case (let dataBytes, let pointers):
      appendInterpolation(
        ".init(safeDataBytes: \(dataBytes), pointers: \(pointers))"
      )
    }
  }
}

extension Optional {
  fileprivate func orMissing(in generator: borrowing Generator, fieldName: String)
    throws(GenerateError) -> Wrapped
  {
    if let value = self {
      value
    } else {
      throw .missingValue(path: generator.errorPath, fieldName: fieldName)
    }
  }
}

func deserializationIsFallible(field: Field) -> Bool {
  guard let which = try? field.slot?.type().which() else {
    // Group fields can be trivially deserialized.
    return false
  }

  switch which {
  case .void, .bool, .int8, .int16, .int32, .int64, .uint8, .uint16, .uint32, .uint64,
    .float32, .float64, .anyPointer(_):
    return false

  case .text, .data, .list(_), .enum(_), .struct(_), .interface(_):
    return true
  }
}

private func ident(_ text: some StringProtocol) -> Substring {
  switch text {
  case "self", "struct", "enum":
    "`\(text)`"
  default:
    .init(text)
  }
}

private func typeIdent(_ text: some StringProtocol) -> Substring {
  switch text {
  case "Type":
    "`\(text)`"
  default:
    .init(text)
  }
}

private func id(_ id: UInt64) -> String { "0x\(String(id, radix: 16))" }

private struct UnionInformation {
  let discriminantOffset: UInt32
  let fields: [(name: String, field: Field)]

  init(
    discriminantOffset: UInt32,
    fields: [(String, Field)],
    dataWords: UInt32,
    in generator: borrowing Generator
  ) throws(GenerateError) {
    self.discriminantOffset = discriminantOffset
    self.fields = fields
  }

  func writeExpr(discriminantValue: UInt16) -> String {
    "struct$.write(UInt16(\(discriminantValue)), atByte: \(discriminantOffset * 2))"
  }
}

/// Runs `f()`, converting `PointerError`s to `GenerateError.invalidSchema`.
///
/// We use an `@autoclosure` rather than a regular closure not to shorten call sites, but because
/// Swift cannot infer that `f` only throws `PointerError` with a regular closure.
func mapError<R>(_ f: @autoclosure () throws(PointerError) -> R) throws(GenerateError) -> R {
  do {
    return try f()
  } catch let error {
    throw .invalidSchema(error)
  }
}

/// ID of `/capnp/schema.capnp`.
let schemaCapnpId: UInt64 = 0xa93f_c509_624c_72d9
/// ID of `/swift.capnp`.
let swiftCapnpId: UInt64 = 0xdbaa_7e67_4e81_c2c3
/// ID of the `$Swift.module` annotation.
let swiftCapnpModuleAnnotationId: UInt64 = 0xb123_04eb_b885_c9c2

// spell-checker: ignore subrange uppercased
