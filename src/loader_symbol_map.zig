// Generated file, do not edit.
// version: 0.1.0

const std = @import("std");
const sc = @import("sc_minimal.zig");

const HandleTypes = struct {
    Instance: type,
    Adapter: type,
    Device: type,
};

fn Functions(handle_types: HandleTypes) type {
    return struct {
        createInstance: fn (
            allocator: ?*sc.HostAllocator,
        ) *handle_types.Instance,
        destroyInstance: fn (
            instance: *handle_types.Instance,
        ) void,
        getSlot: fn (
            instance: *handle_types.Instance,
            name: [*:0]const u8,
        ) usize,
        enumerateAdapters: fn (
            instance: *handle_types.Instance,
            adapters_capacity: usize,
            adapters: ?[*]*handle_types.Adapter,
            adapter_count: *usize,
        ) void,
        createDevice: fn (
            instance: *handle_types.Instance,
            adapter: *handle_types.Adapter,
        ) *handle_types.Device,
        destroyDevice: fn (
            device: *handle_types.Device,
        ) void,
    };
}

const Error = error{
    Unknown,
    OutOfMemory,
    OutOfDeviceMemory,
    DeviceLost,
    SurfaceLost,
    NoBackbuffer,
    MalformedScir,
    UnsupportedScirVersion,
    UnsupportedScirBytecode,
};

fn cResult(result: anytype) sc.Result {
    if (result) return .ok else |err| return switch (@as(Error, err)) {
        error.Unknown => .unknown,
        error.OutOfMemory => .out_of_memory,
        error.OutOfDeviceMemory => .out_of_device_memory,
        error.DeviceLost => .device_lost,
        error.SurfaceLost => .surface_lost,
        error.NoBackbuffer => .no_backbuffer,
        error.MalformedScir => .malformed_scir,
        error.UnsupportedScirVersion => .unsupported_scir_version,
        error.UnsupportedScirBytecode => .unsupported_scir_bytecode,
    };
}

fn CFunctions(comptime handle_types: HandleTypes, comptime functions: Functions(handle_types)) type {
    return struct {
        pub fn createInstance(
            allocator: ?*sc.HostAllocator,
        ) callconv(sc.@"callconv") *handle_types.Instance {
            return functions.createInstance(
                allocator,
            );
        }

        pub fn destroyInstance(
            instance: *handle_types.Instance,
        ) callconv(sc.@"callconv") void {
            return functions.destroyInstance(
                instance,
            );
        }

        pub fn getSlot(
            instance: *handle_types.Instance,
            name: [*:0]const u8,
        ) callconv(sc.@"callconv") usize {
            return functions.getSlot(
                instance,
                name,
            );
        }

        pub fn enumerateAdapters(
            instance: *handle_types.Instance,
            adapters_capacity: usize,
            adapters: ?[*]*handle_types.Adapter,
            adapter_count: *usize,
        ) callconv(sc.@"callconv") void {
            return functions.enumerateAdapters(
                instance,
                adapters_capacity,
                adapters,
                adapter_count,
            );
        }

        pub fn createDevice(
            instance: *handle_types.Instance,
            adapter: *handle_types.Adapter,
        ) callconv(sc.@"callconv") *handle_types.Device {
            return functions.createDevice(
                instance,
                adapter,
            );
        }

        pub fn destroyDevice(
            device: *handle_types.Device,
        ) callconv(sc.@"callconv") void {
            return functions.destroyDevice(
                device,
            );
        }
    };
}

pub fn map(
    comptime handle_types: HandleTypes,
    comptime functions: Functions(handle_types),
) std.StaticStringMap(*const anyopaque) {
    const c_functions = CFunctions(handle_types, functions);
    return .initComptime(@as([]const struct { []const u8, *const anyopaque }, &.{
        .{ "scCreateInstance", @ptrCast(&c_functions.createInstance) },
        .{ "scDestroyInstance", @ptrCast(&c_functions.destroyInstance) },
        .{ "scGetSlot", @ptrCast(&c_functions.getSlot) },
        .{ "scEnumerateAdapters", @ptrCast(&c_functions.enumerateAdapters) },
        .{ "scCreateDevice", @ptrCast(&c_functions.createDevice) },
        .{ "scDestroyDevice", @ptrCast(&c_functions.destroyDevice) },
    }));
}
