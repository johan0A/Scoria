const std = @import("std");
const sc = @import("sc.zig");
const DescriptorAllocator = @This();

heap: sc.DescriptorHeap,
index_next: u32 = 0,
free_list_heads: [mip_count_max]u32 = @splat(free_list_end),
free_list_next: []u32,

const mip_count_max = 16;
const free_list_end = std.math.maxInt(u32);

pub const Range = struct { index: u32, count: u32 };
pub const Kind = enum { view, storage };

pub fn init(gpa: std.mem.Allocator, heap: sc.DescriptorHeap) !DescriptorAllocator {
    return .{ .heap = heap, .free_list_next = try gpa.alloc(u32, heap.capacity) };
}

pub fn deinit(allocator: *DescriptorAllocator, gpa: std.mem.Allocator) void {
    gpa.free(allocator.free_list_next);
}

pub fn allocMips(allocator: *DescriptorAllocator, texture: *sc.Texture, kind: Kind, desc: sc.TextureViewDesc) !Range {
    std.debug.assert(desc.mip_count >= 1 and desc.mip_count <= mip_count_max);

    var descriptors: [mip_count_max]sc.Descriptor = undefined;
    for (descriptors[0..desc.mip_count], desc.base_mip..) |*descriptor, mip| {
        var mip_desc = desc;
        mip_desc.base_mip = @intCast(mip);
        mip_desc.mip_count = 1;
        descriptor.* = switch (kind) {
            .view => try texture.viewDescriptor(mip_desc),
            .storage => try texture.storageDescriptor(mip_desc),
        };
    }

    const free_list_head = &allocator.free_list_heads[desc.mip_count - 1];
    const index = index: {
        if (free_list_head.* != free_list_end) {
            const index = free_list_head.*;
            free_list_head.* = allocator.free_list_next[index];
            break :index index;
        }
        if (allocator.index_next + desc.mip_count > allocator.heap.capacity) return error.OutOfDescriptors;
        defer allocator.index_next += desc.mip_count;
        break :index allocator.index_next;
    };
    for (descriptors[0..desc.mip_count], index..) |*descriptor, slot| allocator.heap.store(descriptor, slot);
    return .{ .index = index, .count = desc.mip_count };
}

pub fn free(allocator: *DescriptorAllocator, range: Range) void {
    allocator.free_list_next[range.index] = allocator.free_list_heads[range.count - 1];
    allocator.free_list_heads[range.count - 1] = range.index;
}
