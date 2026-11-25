const std = @import("std");
const impl = @import("vulkan_implementation/vulkan_implementation.zig");
const sc = impl.sc;
const symbol_map = @import("loader_symbol_map.zig");

pub export fn scSymbol(name: [*:0]u8) callconv(sc.@"callconv") *const anyopaque {
    const map = symbol_map.map(sc, .{
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

fn createInstance(allocator: ?*sc.HostAllocator) *sc.Instance {
    const instance = impl.Instance.create(allocator);
    instance.header = @ptrCast(&table);
    return instance;
}

fn destroyInstance(instance: *sc.Instance) void {
    impl.Instance.destroyInstance(instance);
}

fn getSlot(instance: *sc.Instance, name: [*:0]const u8) usize {
    _ = instance;
    slot_index += 1;
    table[slot_index] = impl.symbol(name);
    return slot_index;
}

fn enumerateAdapters(
    instance: *sc.Instance,
    adapters_capacity: usize,
    adapters: ?[*]*sc.Adapter,
    adapter_count: *usize,
) !void {
    return impl.Instance.enumerateAdapters(instance, adapters_capacity, adapters, adapter_count);
}

fn createDevice(instance: *sc.Instance, adapter: *sc.Adapter) *sc.Device {
    return impl.Device.create(instance, adapter);
}

fn destroyDevice(device: *sc.Device) void {
    impl.Device.destroy(device);
}
