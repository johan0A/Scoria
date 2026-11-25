const std = @import("std");
const sc = @import("sc.zig");
const DescriptorHeap = @This();

memory: sc.heap.Allocation(u8, null),
alignment: std.mem.Alignment,
descriptor_size: usize,
capacity: u32,

pub fn init(device: *sc.Device, allocator: sc.DeviceAllocator, capacity: u32) sc.DeviceAllocator.Error!DescriptorHeap {
    const size_align = device.info().descriptor_size_and_heap_align;
    return .{
        .memory = try allocator.runtimeAlignedAlloc(u8, size_align.alignment(), size_align.size * capacity, .upload),
        .alignment = size_align.alignment(),
        .descriptor_size = size_align.size,
        .capacity = capacity,
    };
}

pub fn deinit(heap: DescriptorHeap, allocator: sc.DeviceAllocator) void {
    allocator.runtimeAlignedFree(heap.memory.device(), heap.alignment, .upload);
}

pub fn store(heap: DescriptorHeap, descriptor: *const sc.Descriptor, index: usize) void {
    @memcpy(heap.memory.host()[heap.descriptor_size * index ..][0..heap.descriptor_size], descriptor.data[0..heap.descriptor_size]);
}
