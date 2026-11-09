const std = @import("std");
const SamplerDesc = @import("sampler_desc.zig").SamplerDesc;

pub const magic: [4]u8 = "scir".*;
pub const version: Version = .{ .major = 0, .minor = 2 };
pub const bytecode_size_max = 1 << 30;
pub const sampler_count_max = (1 << 30) / sampler_size;

const header_size = 20;
const sampler_size = @sizeOf(u64);
const spirv_magic = 0x07230203;

pub const Version = struct {
    major: u16,
    minor: u16,
};

pub const Bytecode = enum(u32) {
    spirv = 0,
    _,
};

pub const ParseError = error{
    MalformedScir,
    UnsupportedScirVersion,
};

pub const Shader = struct {
    version: Version,
    bytecode_kind: Bytecode,
    bytecode: []const u8,
    sampler_bytes: []const u8,

    pub fn samplerCount(shader: Shader) usize {
        return shader.sampler_bytes.len / sampler_size;
    }

    pub fn sampler(shader: Shader, index: usize) SamplerDesc {
        std.debug.assert(index < shader.samplerCount());
        return @bitCast(std.mem.readInt(u64, shader.sampler_bytes[index * sampler_size ..][0..sampler_size], .little));
    }

    pub fn samplerIterator(shader: Shader) SamplerIterator {
        return .{ .shader = shader };
    }

    pub fn spirvAlloc(shader: Shader, gpa: std.mem.Allocator) error{ UnsupportedScirBytecode, OutOfMemory }![]u32 {
        if (shader.bytecode_kind != .spirv) return error.UnsupportedScirBytecode;
        const words = try gpa.alloc(u32, shader.bytecode.len / 4);
        @memcpy(std.mem.sliceAsBytes(words), shader.bytecode);
        return words;
    }
};

pub const SamplerIterator = struct {
    shader: Shader,
    index: usize = 0,

    pub fn next(it: *SamplerIterator) ?SamplerDesc {
        if (it.index == it.shader.samplerCount()) return null;
        defer it.index += 1;
        return it.shader.sampler(it.index);
    }
};

pub const EncodeError = error{TooLarge};

pub const Encoder = struct {
    w: *std.Io.Writer,
    bytecode_size_left: u32,
    sampler_count_left: u32,

    pub fn begin(
        w: *std.Io.Writer,
        bytecode_kind: Bytecode,
        bytecode_size: u32,
        sampler_count: u32,
    ) (EncodeError || std.Io.Writer.Error)!Encoder {
        if (bytecode_size > bytecode_size_max or sampler_count > sampler_count_max) return error.TooLarge;

        try w.writeAll(&magic);
        try w.writeInt(u16, version.major, .little);
        try w.writeInt(u16, version.minor, .little);
        try w.writeInt(u32, @backingInt(bytecode_kind), .little);
        try w.writeInt(u32, bytecode_size, .little);
        try w.writeInt(u32, sampler_count, .little);

        return .{
            .w = w,
            .bytecode_size_left = bytecode_size,
            .sampler_count_left = sampler_count,
        };
    }

    pub fn bytecode(e: *Encoder, bytes: []const u8) std.Io.Writer.Error!void {
        std.debug.assert(bytes.len <= e.bytecode_size_left);
        e.bytecode_size_left -= @intCast(bytes.len);
        try e.w.writeAll(bytes);
    }

    pub fn sampler(e: *Encoder, s: SamplerDesc) std.Io.Writer.Error!void {
        std.debug.assert(e.bytecode_size_left == 0);
        std.debug.assert(e.sampler_count_left != 0);
        e.sampler_count_left -= 1;
        try e.w.writeInt(u64, @bitCast(s), .little);
    }

    pub fn end(e: *Encoder) void {
        std.debug.assert(e.bytecode_size_left == 0);
        std.debug.assert(e.sampler_count_left == 0);
        e.* = undefined;
    }
};

comptime {
    std.debug.assert(@sizeOf(SamplerDesc) == sampler_size);
}

pub fn parse(bytes: []const u8) ParseError!Shader {
    if (bytes.len < header_size or !std.mem.eql(u8, bytes[0..4], &magic)) return error.MalformedScir;

    const file_version: Version = .{
        .major = std.mem.readInt(u16, bytes[4..6], .little),
        .minor = std.mem.readInt(u16, bytes[6..8], .little),
    };
    if (file_version.major != version.major or
        (version.major == 0 and file_version.minor != version.minor)) return error.UnsupportedScirVersion;

    const bytecode_kind: Bytecode = @fromBackingInt(@intCast(std.mem.readInt(u32, bytes[8..12], .little)));
    const bytecode_size = std.mem.readInt(u32, bytes[12..16], .little);
    const sampler_count = std.mem.readInt(u32, bytes[16..20], .little);
    if (bytecode_size > bytecode_size_max or sampler_count > sampler_count_max) return error.MalformedScir;

    const samplers_offset = header_size + @as(usize, bytecode_size);
    const end = samplers_offset + @as(usize, sampler_count) * sampler_size;
    if (bytes.len < end) return error.MalformedScir;

    const bytecode = bytes[header_size..samplers_offset];
    try validateBytecode(bytecode_kind, bytecode);

    return .{
        .version = file_version,
        .bytecode_kind = bytecode_kind,
        .bytecode = bytecode,
        .sampler_bytes = bytes[samplers_offset..end],
    };
}

pub fn validateBytecode(bytecode_kind: Bytecode, bytecode: []const u8) error{MalformedScir}!void {
    switch (bytecode_kind) {
        .spirv => if (bytecode.len < 4 or bytecode.len % 4 != 0 or
            std.mem.readInt(u32, bytecode[0..4], .little) != spirv_magic) return error.MalformedScir,
        _ => {},
    }
}

/// usage: scir <output> <bytecode kind> <bytecode> [sampler as hex]...
pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);

    const bytecode_kind = std.meta.stringToEnum(Bytecode, args[2]) orelse return error.UnknownBytecodeKind;
    const bytecode = try std.Io.Dir.readFileAlloc(.cwd(), init.io, args[3], arena, .unlimited);
    try validateBytecode(bytecode_kind, bytecode);
    const sampler_args = args[4..];

    const out_file = try std.Io.Dir.createFile(.cwd(), init.io, args[1], .{});
    var out_writer_buffer: [1024]u8 = undefined;
    var out_writer = out_file.writer(init.io, &out_writer_buffer);

    var encoder: Encoder = try .begin(&out_writer.interface, bytecode_kind, @intCast(bytecode.len), @intCast(sampler_args.len));
    try encoder.bytecode(bytecode);
    for (sampler_args) |arg| {
        var sampler_bytes: [8]u8 = undefined;
        _ = try std.fmt.hexToBytes(&sampler_bytes, arg);
        try encoder.sampler(@bitCast(std.mem.readInt(u64, &sampler_bytes, .little)));
    }
    encoder.end();
    try out_writer.flush();
}
