// Generated file, do not edit.
// version: 0.1.0

const std = @import("std");

fn Functions(sc: type) type {
    return struct {
        createInstance: fn (
            allocator: ?*sc.HostAllocator,
        ) *sc.Instance,
        destroyInstance: fn (
            instance: *sc.Instance,
        ) void,
        getSlot: fn (
            instance: *sc.Instance,
            name: [*:0]const u8,
        ) usize,
        enumerateAdapters: fn (
            instance: *sc.Instance,
            adapters_capacity: usize,
            adapters: ?[*]*sc.Adapter,
            adapter_count: *usize,
        ) error{
            OutOfMemory,
            OutOfDeviceMemory,
            Unknown,
        }!void,
        createDevice: fn (
            instance: *sc.Instance,
            adapter: *sc.Adapter,
        ) *sc.Device,
        destroyDevice: fn (
            device: *sc.Device,
        ) void,
    };
}

fn CFunctions(comptime sc: type, comptime functions: Functions(sc)) type {
    return struct {
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

        pub fn createInstance(
            allocator: ?*sc.HostAllocator,
        ) callconv(sc.@"callconv") *sc.Instance {
            return functions.createInstance(
                allocator,
            );
        }

        pub fn destroyInstance(
            instance: *sc.Instance,
        ) callconv(sc.@"callconv") void {
            return functions.destroyInstance(
                instance,
            );
        }

        pub fn getSlot(
            instance: *sc.Instance,
            name: [*:0]const u8,
        ) callconv(sc.@"callconv") usize {
            return functions.getSlot(
                instance,
                name,
            );
        }

        pub fn enumerateAdapters(
            instance: *sc.Instance,
            adapters_capacity: usize,
            adapters: ?[*]*sc.Adapter,
            adapter_count: *usize,
        ) callconv(sc.@"callconv") sc.Result {
            return cResult(functions.enumerateAdapters(
                instance,
                adapters_capacity,
                adapters,
                adapter_count,
            ));
        }

        pub fn createDevice(
            instance: *sc.Instance,
            adapter: *sc.Adapter,
        ) callconv(sc.@"callconv") *sc.Device {
            return functions.createDevice(
                instance,
                adapter,
            );
        }

        pub fn destroyDevice(
            device: *sc.Device,
        ) callconv(sc.@"callconv") void {
            return functions.destroyDevice(
                device,
            );
        }
    };
}

pub fn map(comptime sc: type, comptime functions: Functions(sc)) std.StaticStringMap(*const anyopaque) {
    const c_functions = CFunctions(sc, functions);
    return .initComptime(@as([]const struct { []const u8, *const anyopaque }, &.{
        .{ "scCreateInstance", @ptrCast(&c_functions.createInstance) },
        .{ "scDestroyInstance", @ptrCast(&c_functions.destroyInstance) },
        .{ "scGetSlot", @ptrCast(&c_functions.getSlot) },
        .{ "scEnumerateAdapters", @ptrCast(&c_functions.enumerateAdapters) },
        .{ "scCreateDevice", @ptrCast(&c_functions.createDevice) },
        .{ "scDestroyDevice", @ptrCast(&c_functions.destroyDevice) },
    }));
}
