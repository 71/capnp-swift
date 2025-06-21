#!/usr/bin/env -S deno run --allow-net=raw.githubusercontent.com --allow-run --allow-write
import { Message } from "npm:capnp-es@0.0.7";
import {
  CodeGeneratorRequest,
  Field,
  Field_Slot,
  Node,
  Type,
  Value,
} from "npm:capnp-es@0.0.7/capnp/schema";

if (Deno.args.length !== 0) {
  console.error(`Usage: deno run ${import.meta.filename}

Converts schema.capnp into Swift source code.

This script was used to bootstrap capnpc-swift, but is no longer needed (as capnpc-swift can
generate its own code now). It is kept here for historical purposes.

Unlike the real capnpc-swift generator, this script only supports reading messages, and is not
general-purpose: it is only intended to read /capnp/schema.capnp, and may not work with other
schemas.
`);
  Deno.exit(1);
}

Deno.exit(await main());

// ------------------------------------------------------------------------------------------------
// MARK: Main logic

async function main(): Promise<number> {
  // Parse schema into a `CodeGeneratorRequest`.
  const { code, stdout: schemaCapnp } = await new Deno.Command("capnp", {
    args: [
      "compile",
      "--no-standard-import",
      "--output=-",
      "Sources/CapnProtoSchema/schema.capnp",
    ],
    stdout: "piped",
    stderr: "inherit",
  }).output();

  if (code !== 0) {
    console.error(`capnp compile exited with code ${code}`);
    return 1;
  }

  // Convert the schema to Swift.
  const requestMessage = new Message(schemaCapnp, /*packed=*/ false);
  const request = requestMessage.getRoot(CodeGeneratorRequest);

  await Deno.writeTextFile(
    "Sources/CapnProtoSchema/Schema.capnp.swift",
    emitSwiftSchema(request.nodes),
  );

  return 0;
}

// ------------------------------------------------------------------------------------------------
// MARK: File generation

function emitSwiftSchema(nodes: readonly Node[]): string {
  let linePrefix = "";
  const indent = () => linePrefix += "  ";
  const dedent = () => linePrefix = linePrefix.slice(0, -2);

  const swiftLines: string[] = [];
  const extensionLines: string[] = [];

  const swift = (strings: TemplateStringsArray, ...values: unknown[]) => {
    if (values.length === 0 && strings[0].length === 0) {
      swiftLines.push("");
    } else {
      swiftLines.push(linePrefix + String.raw(strings, ...values));
    }
  };
  const ext = (strings: TemplateStringsArray, ...values: unknown[]) => {
    extensionLines.push(String.raw(strings, ...values));
  };

  const nodeMap = new Map<bigint, Node>(nodes.map((node) => [node.id, node]));
  const nodeById = (id: bigint) => nodeMap.get(id)!;
  const identPath: string[] = [];

  const emitStruct = (node: Node, nodeIdent: string = ident(node)): void => {
    identPath.push(nodeIdent);

    const struct = node.struct;

    swift`public struct ${nodeIdent}: CapnProto.Struct {`;
    indent();

    emitNestedNodes(node);

    swift`public static let id: UInt64 = ${id(node.id)}`;
    swift`public static let size: CapnProto.StructSize = .init(safeDataBytes: ${
      struct.dataWordCount * 8
    }, pointers: ${struct.pointerCount})`;
    swift`public static let firstFieldSize: CapnProto.ListElementSize? = nil`;
    swift``;
    swift`public var struct$: CapnProto.StructPointer`;
    swift``;
    swift`public init(_ struct$: CapnProto.StructPointer) { self.struct$ = struct$ }`;
    swift``;

    if (struct.discriminantCount > 0) {
      const unionFields = struct.fields.filter((f) =>
        f.discriminantValue !== 0xffff
      );

      swift`public enum Which {`;
      indent();
      swift`public enum Discriminant: UInt16, CapnProto.EnumOrDiscriminant {`;
      swift`    public static let defaultValue: Self = .${
        ident(unionFields[0].name)
      }`;
      swift`    public static let maxValue: Self = .${
        ident(unionFields.at(-1)!.name)
      }`;
      swift``;
      ext`extension CapnProto.EnumValue<${
        identPath.join(".")
      }.Which.Discriminant> {`;

      for (const field of unionFields) {
        swift`    case ${ident(field.name)} = ${field.discriminantValue}`;
        ext`    public static let ${ident(field.name)}: CapnProto.EnumValue<${
          identPath.join(".")
        }.Which.Discriminant> = .init(${field.discriminantValue})`;
      }

      dedent();
      swift`}`;
      swift``;
      ext`}`;
      ext``;

      for (const field of unionFields) {
        const fieldType = field._isSlot && field.slot.type.which() === Type.VOID
          ? ""
          : `(${fieldTypeName(field, nodeById)})`;

        swift`    case ${ident(field.name)}${fieldType}`;
      }
      swift`}`;
      swift``;

      swift`public var whichDiscriminant: CapnProto.EnumValue<Which.Discriminant> { struct$.readEnum(atByte: ${
        struct.discriminantOffset * 2
      }, defaultValue: .${ident(unionFields[0].name)}) }`;
      swift``;

      swift`public func which() throws(CapnProto.PointerError) -> Which? {`;
      swift`    switch whichDiscriminant.rawValue {`;
      for (const field of unionFields) {
        const args = field._isSlot && field.slot.type.which() === Type.VOID
          ? ""
          : `(${fieldExpr(field, nodeById)})`;

        swift`    case ${field.discriminantValue}: .${
          ident(field.name)
        }${args}`;
      }
      swift`    default: nil`;
      swift`    }`;
      swift`}`;
      swift``;
    }

    for (const field of struct.fields) {
      emitField(field);
    }

    dedent();
    swift`}`;
    swift``;

    identPath.pop();
  };
  const emitField = (field: Field): string => {
    let typeName = fieldTypeName(field, nodeById);
    let getter = fieldExpr(field, nodeById);

    if (field._isGroup) {
      emitStruct(nodeById(field.group.typeId), typeName);
    }

    if (field.discriminantValue !== 0xffff) {
      if (!typeName.endsWith("?")) typeName += "?";
      getter =
        `whichDiscriminant.rawValue == ${field.discriminantValue} ? ${getter} : nil`;
    }

    if (/\btry\s/.test(getter)) {
      swift`public func ${
        ident(field.name)
      }() throws(CapnProto.PointerError) -> ${typeName} { ${getter} }`;
    } else {
      swift`public var ${ident(field.name)}: ${typeName} { ${getter} }`;
    }
    swift``;

    return typeName;
  };
  const emitEnum = (node: Node): void => {
    const enum_ = node.enum;

    swift`public enum ${ident(node)}: UInt16, CapnProto.Enum {`;
    ext`extension CapnProto.EnumValue<${ident(node)}> {`;
    indent();

    swift`public static let id: UInt64 = ${id(node.id)}`;
    swift`public static let defaultValue: Self = .${
      ident(enum_.enumerants[0].name)
    }`;
    swift`public static let maxValue: Self = .${
      ident(enum_.enumerants[enum_.enumerants.length - 1].name)
    }`;
    swift``;

    let enumerantValue = 0;
    for (const enumerant of enum_.enumerants) {
      swift`case ${ident(enumerant.name)} = ${enumerantValue++}`;
      ext`public static let ${ident(enumerant.name)}: CapnProto.EnumValue<${
        ident(node)
      }> = .init(${enumerantValue - 1})`;
    }

    dedent();
    swift`}`;
    swift``;
    ext`}`;
    ext``;
  };
  const emitNestedNodes = (node: Node): void => {
    for (const nestedNode of node.nestedNodes) {
      const node = nodeById(nestedNode.id);

      switch (node.which()) {
        case Node.STRUCT:
          emitStruct(node);
          break;
        case Node.ENUM:
          emitEnum(node);
          break;
      }
    }
  };

  swift`// Generated by bootstrap.ts; do not edit.`;
  swift`import CapnProto`;
  swift``;

  const file = nodes.find((node) => node.which() === Node.FILE)!;

  emitNestedNodes(file);

  return [...swiftLines, "", ...extensionLines].join("\n");
}

// ------------------------------------------------------------------------------------------------
// MARK: Helpers

function id(id: bigint): string {
  return `0x${id.toString(16).padStart(16, "0")}`;
}

function ident(ident: Node | string): string {
  if (typeof ident !== "string") {
    ident = ident.displayName.slice(ident.displayNamePrefixLength);
  }

  return /^(struct|enum)$/.test(ident) ? `\`${ident}\`` : ident;
}

function fieldTypeName(field: Field, nodeById: (id: bigint) => Node): string {
  switch (field.which()) {
    case Field.SLOT:
      return typeName(field.slot.type, (id) => nodeById(id));
    case Field.GROUP: {
      const group = field.group;
      const groupNode = nodeById(group.typeId);
      const groupName = groupNode.displayName.slice(
        groupNode.displayNamePrefixLength,
      );
      return groupName[0].toUpperCase() + groupName.slice(1);
    }
  }
}

function fieldExpr(field: Field, nodeById: (id: bigint) => Node): string {
  switch (field.which()) {
    case Field.SLOT:
      return fieldSlotExpr(field.slot, nodeById);
    case Field.GROUP:
      return ".init(struct$)";
  }
}

function typeName(type: Type, node: (id: bigint) => Node): string {
  switch (type.which()) {
    case Type.VOID:
      return "CapnProto.VoidValue";
    case Type.BOOL:
      return "Bool";
    case Type.INT8:
      return "Int8";
    case Type.INT16:
      return "Int16";
    case Type.INT32:
      return "Int32";
    case Type.INT64:
      return "Int64";
    case Type.UINT8:
      return "UInt8";
    case Type.UINT16:
      return "UInt16";
    case Type.UINT32:
      return "UInt32";
    case Type.UINT64:
      return "UInt64";
    case Type.FLOAT32:
      return "Float32";
    case Type.FLOAT64:
      return "Float64";

    case Type.TEXT:
      return `CapnProto.Text`;
    case Type.DATA:
      return `CapnProto.List<UInt8>`;
    case Type.INTERFACE:
      return `CapnProto.AnyCapability`;
    case Type.ANY_POINTER:
      return `CapnProto.AnyPointer?`;

    case Type.LIST:
      return `CapnProto.List<${typeName(type.list.elementType, node)}>`;

    case Type.ENUM:
      return `CapnProto.EnumValue<${fullPath(type.enum.typeId, node)}>`;

    case Type.STRUCT:
      return `${fullPath(type.struct.typeId, node)}`;
  }
}

function fullPath(id: bigint, nodeById: (id: bigint) => Node): string {
  let node = nodeById(id);
  const path: string[] = [];

  while (node.scopeId != 0n) {
    path.push(node.displayName.slice(node.displayNamePrefixLength));

    node = nodeById(node.scopeId);
  }

  return path.reverse().join(".");
}

function fieldSlotExpr(
  slot: Field_Slot,
  nodeById: (id: bigint) => Node,
): string {
  const readPrimitive = (sizeInBytes: number) =>
    `struct$.read(atByte: ${slot.offset * sizeInBytes}, defaultValue: ${
      valueExpr(slot.defaultValue)
    })`;

  switch (slot.type.which()) {
    case Type.VOID:
      return `.init()`;

    case Type.BOOL:
      return `struct$.read(atBit: ${slot.offset}, defaultValue: ${slot.defaultValue.bool})`;

    case Type.INT8:
    case Type.UINT8:
      return readPrimitive(1);

    case Type.INT16:
    case Type.UINT16:
      return readPrimitive(2);

    case Type.INT32:
    case Type.UINT32:
    case Type.FLOAT32:
      return readPrimitive(4);

    case Type.INT64:
    case Type.UINT64:
    case Type.FLOAT64:
      return readPrimitive(8);

    case Type.ENUM:
      return `struct$.readEnum(atByte: ${slot.offset * 2}, defaultValue: .${
        ident(
          nodeById(slot.type.enum.typeId).enum.enumerants.at(
            slot.defaultValue.enum,
          ).name,
        )
      })`;

    case Type.ANY_POINTER:
      return `struct$.readAnyPointer(at: ${slot.offset})`;

    case Type.STRUCT:
      return `try struct$.readStruct(at: ${slot.offset}) ?? .init()`;

    case Type.TEXT:
      return `try struct$.readText(at: ${slot.offset}) ?? .init()`;

    case Type.DATA:
    case Type.LIST:
      return `try struct$.readList(at: ${slot.offset}) ?? .init()`;

    default:
      throw new Error(`unsupported field type: ${slot.type.which()}`);
  }
}

function valueExpr(value: Value): string {
  switch (value.which()) {
    case Value.BOOL:
      return value.bool ? "true" : "false";
    case Value.INT8:
      return `${value.int8}`;
    case Value.INT16:
      return `${value.int16}`;
    case Value.INT32:
      return `${value.int32}`;
    case Value.INT64:
      return `${value.int64}`;
    case Value.UINT8:
      return `${value.uint8}`;
    case Value.UINT16:
      return `${value.uint16}`;
    case Value.UINT32:
      return `${value.uint32}`;
    case Value.UINT64:
      return `${value.uint64}`;
    case Value.FLOAT32:
      return `${value.float32}`;
    case Value.FLOAT64:
      return `${value.float64}`;
    default:
      throw new Error(`unsupported value type: ${value.which()}`);
  }
}

// spell-checker:ignore typealias
