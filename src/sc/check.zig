const std = @import("std");
const sc = @import("sc.zig");
const functions = @import("functions.zig");
const reference = @import("reference.zig");

test "declarations match the registry" {
    @setEvalBranchQuota(100_000);
    comptime checkDecls(sc, reference, "sc");
}

test "every generated function is exposed by sc.zig" {
    @setEvalBranchQuota(100_000);
    std.testing.refAllDecls(functions);
    comptime for (std.meta.declarations(functions)) |function_name| {
        if (!isExposed(@field(functions, function_name)))
            fail("functions." ++ function_name, "not exposed by any declaration in sc.zig or its opaques", .{});
    };
}

fn checkDecls(comptime Actual: type, comptime Expected: type, comptime path: []const u8) void {
    inline for (comptime std.meta.declarations(Expected)) |name| {
        const decl_path = path ++ "." ++ name;
        if (!@hasDecl(Actual, name)) fail(decl_path, "missing declaration", .{});
        const actual = @field(Actual, name);
        const expected = @field(Expected, name);
        if (@TypeOf(actual) != @TypeOf(expected)) {
            fail(decl_path, "expected a '{s}', found a '{s}'", .{ @typeName(@TypeOf(expected)), @typeName(@TypeOf(actual)) });
        }
        if (@TypeOf(expected) == type) {
            checkType(actual, expected, decl_path);
        } else if (!std.meta.eql(actual, expected)) {
            fail(decl_path, "expected value {any}, found {any}", .{ expected, actual });
        }
    }
}

fn checkType(comptime Actual: type, comptime Expected: type, comptime path: []const u8) void {
    const expected_tag = std.meta.activeTag(@typeInfo(Expected));
    switch (@typeInfo(Expected)) {
        .@"opaque", .@"enum", .@"struct" => if (std.meta.activeTag(@typeInfo(Actual)) != expected_tag) {
            fail(path, "expected {s}, found '{s}'", .{ @tagName(expected_tag), @typeName(Actual) });
        },
        else => if (Actual != Expected) fail(path, "expected '{s}', found '{s}'", .{ @typeName(Expected), @typeName(Actual) }),
    }
    switch (@typeInfo(Expected)) {
        .@"enum" => |expected| {
            const actual = @typeInfo(Actual).@"enum";
            if (actual.tag_type != expected.tag_type) {
                fail(path, "expected tag type '{s}', found '{s}'", .{ @typeName(expected.tag_type), @typeName(actual.tag_type) });
            }
            if (actual.mode != expected.mode) fail(path, "expected an {s} enum", .{@tagName(expected.mode)});
            if (actual.field_names.len != expected.field_names.len) {
                fail(path, "expected {d} values, found {d}", .{ expected.field_names.len, actual.field_names.len });
            }
            for (actual.field_names, actual.field_values, expected.field_names, expected.field_values) |actual_name, actual_value, expected_name, expected_value| {
                if (!std.mem.eql(u8, actual_name, expected_name) or actual_value != expected_value) {
                    fail(path, "expected '{s} = {d}', found '{s} = {d}'", .{ expected_name, expected_value, actual_name, actual_value });
                }
            }
        },
        .@"struct" => |expected| {
            const actual = @typeInfo(Actual).@"struct";
            if (actual.layout != expected.layout) {
                fail(path, "expected {s} layout, found {s}", .{ @tagName(expected.layout), @tagName(actual.layout) });
            }
            if (actual.backing_integer != expected.backing_integer) {
                fail(path, "expected backing integer '{?}', found '{?}'", .{ expected.backing_integer, actual.backing_integer });
            }
            if (actual.field_names.len != expected.field_names.len) {
                fail(path, "expected {d} fields, found {d}", .{ expected.field_names.len, actual.field_names.len });
            }

            inline for (0..expected.field_names.len) |index| {
                const name = actual.field_names[index];
                const field_path = path ++ "." ++ name;

                const is_size_align_alignment = Actual == sc.SizeAlign and std.mem.eql(u8, name, "alignment_byte_units");
                const registry_name: []const u8 = if (is_size_align_alignment) "alignment" else name;

                if (!std.mem.eql(u8, registry_name, expected.field_names[index])) {
                    fail(field_path, "expected field '{s}', found '{s}'", .{ expected.field_names[index], registry_name });
                }

                const Field = expected.field_types[index];
                if (actual.field_types[index] != Field) {
                    fail(field_path, "expected type '{s}', found '{s}'", .{ @typeName(Field), @typeName(actual.field_types[index]) });
                }
                const actual_attrs = actual.field_attrs[index];
                const expected_attrs = expected.field_attrs[index];
                if (actual_attrs.@"align" != expected_attrs.@"align") {
                    fail(field_path, "expected alignment {?d}, found {?d}", .{ expected_attrs.@"align", actual_attrs.@"align" });
                }
                const actual_default = actual_attrs.defaultValue(Field);
                const expected_default = expected_attrs.defaultValue(Field);
                if (!std.meta.eql(actual_default, expected_default)) {
                    fail(field_path, "expected default {any}, found {any}", .{ expected_default, actual_default });
                }
            }
        },
        else => {},
    }
    switch (@typeInfo(Expected)) {
        .@"opaque", .@"enum", .@"struct" => checkDecls(Actual, Expected, path),
        else => {},
    }
}

fn isExposed(comptime function: anytype) bool {
    inline for (comptime std.meta.declarations(sc)) |name| {
        const decl = @field(sc, name);
        if (@TypeOf(decl) == @TypeOf(function) and &decl == &function) return true;
        if (@TypeOf(decl) == type and (@typeInfo(decl) == .@"opaque" or @typeInfo(decl) == .@"struct")) {
            inline for (comptime std.meta.declarations(decl)) |method_name| {
                const method = @field(decl, method_name);
                if (@TypeOf(method) == @TypeOf(function) and &method == &function) return true;
            }
        }
    }
    return false;
}

fn fail(comptime path: []const u8, comptime format: []const u8, args: anytype) noreturn {
    @compileError(path ++ ": " ++ std.fmt.comptimePrint(format, args));
}
