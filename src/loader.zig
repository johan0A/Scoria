const std = @import("std");
const gpu = @import("sf_minimal.zig");
const impl = @import("vulkan_implementation.zig");
const symbol_map = @import("loader_symbol_map.zig");

pub export fn sfSymbol(name: [*:0]u8) callconv(gpu.@"callconv") *const anyopaque {
    const map = symbol_map.map(.{
        .Instance = impl.Object(impl.Instance),
        .Adapter = impl.Adapter,
        .Device = impl.Object(impl.Device),
    }, .{
        .createInstance = createInstance,
        .destroyInstance = destroyInstance,
        .getSlot = getSlot,
        .enumerateAdapters = enumerateAdapters,
        .createDevice = createDevice,
        .destroyDevice = destroyDevice,
    });
    return map.get(std.mem.span(name)).?;
}

var slot_index: usize = 0;
var table: [1024]*const anyopaque = undefined;

fn createInstance(allocator: ?*gpu.HostAllocator) *impl.Object(impl.Instance) {
    const instance = impl.Instance.create(allocator);
    instance.header = @ptrCast(&table);
    return instance;
}

fn destroyInstance(instance: *impl.Object(impl.Instance)) void {
    impl.Instance.destroyInstance(instance);
}

fn getSlot(instance: *impl.Object(impl.Instance), name: [*:0]const u8) usize {
    _ = instance;
    slot_index += 1;
    table[slot_index] = impl.symbol(name);
    return slot_index;
}

fn enumerateAdapters(
    instance: *impl.Object(impl.Instance),
    adapters_capacity: usize,
    adapters: ?[*]*impl.Adapter,
    adapter_count: *usize,
) void {
    impl.Instance.enumerateAdapters(instance, adapters_capacity, adapters, adapter_count);
}

fn createDevice(instance: *impl.Object(impl.Instance), adapter: *impl.Adapter) *impl.Object(impl.Device) {
    return impl.Device.create(instance, adapter);
}

fn destroyDevice(device: *impl.Object(impl.Device)) void {
    impl.Device.destroy(device);
}
