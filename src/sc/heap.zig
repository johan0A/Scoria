const std = @import("std");
const sc = @import("sc.zig");
const Alignment = std.mem.Alignment;

pub const PointerAttributes = struct {
    @"align": ?std.mem.Alignment = null,
    optional: bool = false,
};

pub const PointerInfo = struct {
    pub const Size = enum {
        one,
        many,
    };
    size: Size,
    Element: type,
    attributes: PointerAttributes,
};

pub fn Ptr(
    size: PointerInfo.Size,
    Element: type,
    attributes: PointerAttributes,
) type {
    return extern struct {
        addr: sc.DeviceAddress,

        pub const empty: @This() = .{ .addr = if (alignment) |a| a.toByteUnits() else 1 };

        pub const @"null": @This() = if (attributes.optional) .{ .addr = 0 } else @compileError("pointer is not optional");

        pub const Host = blk: {
            const HostPointer = @Pointer(switch (size) {
                .one => .one,
                .many => .many,
            }, .{
                .@"align" = if (attributes.@"align") |a| a.toByteUnits() else null,
            }, Element, null);
            break :blk if (attributes.optional) ?HostPointer else HostPointer;
        };

        pub const info: PointerInfo = .{
            .size = size,
            .Element = Element,
            .attributes = attributes,
        };

        pub const alignment: ?std.mem.Alignment = attributes.@"align" orelse switch (Element) {
            anyopaque => null, // TODO: replace with @compileError("no align available for uninstantiable type 'anyopaque'")
            else => .of(Element),
        };

        const unwrapped_attributes: PointerAttributes = blk: {
            var a = attributes;
            a.optional = false;
            break :blk a;
        };

        // like zig, an element pointer only keeps the alignment shared by all elements
        const element_attributes: PointerAttributes = blk: {
            const ptr_alignment = alignment orelse break :blk .{};
            const stride = @sizeOf(Element);
            const element_alignment = if (stride == 0) ptr_alignment else ptr_alignment.min(.fromByteUnits(stride & -stride));
            break :blk .{ .@"align" = if (element_alignment == Alignment.of(Element)) null else element_alignment };
        };

        pub fn fromInt(addr: u64) @This() {
            const result: @This() = .{ .addr = addr };
            result.assertAlignment();
            result.assertZero();
            return result;
        }

        pub fn as(ptr: anytype) @This() {
            const Source = @TypeOf(ptr);
            comptime {
                if (!isDevicePtr(Source))
                    @compileError("expected a device pointer, found '" ++ @typeName(Source) ++ "'");
                _ = @as(Host, @as(Source.Host, undefined));
            }
            return .{ .addr = ptr.addr };
        }

        pub fn ptrCast(ptr: anytype) @This() {
            comptime blk: {
                if (!isDevicePtr(@TypeOf(ptr)))
                    @compileError("expected a device pointer, found '" ++ @typeName(@TypeOf(ptr)) ++ "'");
                const source_alignment = @TypeOf(ptr).alignment orelse break :blk;
                const destination_alignment = alignment orelse break :blk;
                if (destination_alignment.compare(.gt, source_alignment))
                    @compileError("cast increases pointer alignment; use alignCast");
            }
            return .{ .addr = ptr.addr };
        }

        pub fn alignCast(ptr: anytype) @This() {
            const Source = @TypeOf(ptr);
            comptime {
                if (!isDevicePtr(Source))
                    @compileError("expected a device pointer, found '" ++ @typeName(Source) ++ "'");
                var a = Source.info.attributes;
                a.@"align" = attributes.@"align";
                _ = @as(Host, @as(Ptr(Source.info.size, Source.info.Element, a).Host, undefined));
            }
            return .fromInt(ptr.addr);
        }

        pub fn isNull(ptr: @This()) bool {
            comptime std.debug.assert(attributes.optional);
            return ptr.addr == 0;
        }

        pub fn unwrap(ptr: @This()) ?Ptr(size, Element, unwrapped_attributes) {
            if (ptr.addr == 0) return null;
            return .fromInt(ptr.addr);
        }

        pub fn slice(ptr: @This(), len: u64) Slice(Element, unwrapped_attributes) {
            comptime std.debug.assert(size == .many);
            ptr.assertZero();
            return .{ .ptr = .fromInt(ptr.addr), .len = len };
        }

        pub fn add(ptr: @This(), n: u64) Ptr(.many, Element, .{}) {
            if (attributes.optional) @compileError("cannot be optional");
            return .{ .addr = ptr.addr + n * @sizeOf(Element) };
        }

        /// Equivalent of `&ptr[index]`.
        pub fn elementPtr(ptr: @This(), index: u64) Ptr(.one, Element, element_attributes) {
            if (size != .many) @compileError("expected a many item pointer");
            if (attributes.optional) @compileError("cannot be optional");
            return .fromInt(ptr.addr + index * @sizeOf(Element));
        }

        fn assertAlignment(ptr: @This()) void {
            if (alignment != null) std.debug.assert(std.mem.isAligned(ptr.addr, alignment.?.toByteUnits()));
        }

        fn assertZero(ptr: @This()) void {
            if (!attributes.optional) std.debug.assert(ptr.addr != 0);
        }
    };
}

pub const SliceInfo = struct {
    Element: type,
    attributes: PointerAttributes,
};

pub fn Slice(
    Element: type,
    attributes: PointerAttributes,
) type {
    return extern struct {
        ptr: Pointer,
        len: u64,

        const Pointer = Ptr(.many, Element, attributes);

        pub const info: SliceInfo = .{
            .Element = Element,
            .attributes = attributes,
        };

        pub const Host = blk: {
            const HostPointer = @Pointer(.slice, .{
                .@"align" = if (attributes.@"align") |a| a.toByteUnits() else null,
            }, Element, null);
            break :blk if (attributes.optional) ?HostPointer else HostPointer;
        };

        pub const empty: @This() = .{ .ptr = .empty, .len = 0 };

        pub fn as(source: anytype) @This() {
            const Source = @TypeOf(source);
            comptime {
                if (!isDeviceSlice(Source) and !isDevicePtr(Source))
                    @compileError("expected a device pointer or slice, found '" ++ @typeName(Source) ++ "'");
                _ = @as(Host, @as(Source.Host, undefined));
            }
            if (comptime isDeviceSlice(Source)) {
                return .{ .ptr = .{ .addr = source.ptr.addr }, .len = source.len };
            } else {
                return .{
                    .ptr = .{ .addr = source.addr },
                    .len = @typeInfo(Source.info.Element).array.len,
                };
            }
        }

        pub fn ptrCast(source: anytype) @This() {
            const Source = @TypeOf(source);
            comptime if (!isDeviceSlice(Source))
                @compileError("expected a device slice, found '" ++ @typeName(Source) ++ "'");
            const byte_count = source.len * @sizeOf(Source.info.Element);
            std.debug.assert(byte_count % @sizeOf(Element) == 0);
            return .{
                .ptr = .ptrCast(source.ptr),
                .len = byte_count / @sizeOf(Element),
            };
        }

        pub fn alignCast(source: anytype) @This() {
            const Source = @TypeOf(source);
            comptime {
                if (!isDeviceSlice(Source))
                    @compileError("expected a device slice, found '" ++ @typeName(Source) ++ "'");
                var a = Source.info.attributes;
                a.@"align" = attributes.@"align";
                _ = @as(Host, @as(Slice(Source.info.Element, a).Host, undefined));
            }
            return .{ .ptr = .fromInt(source.ptr.addr), .len = source.len };
        }

        pub fn asBytes(slice: @This()) Slice(u8, blk: {
            var a = attributes;
            a.@"align" = @TypeOf(slice.ptr).alignment;
            break :blk a;
        }) {
            return .{
                .ptr = .{ .addr = slice.ptr.addr },
                .len = slice.len * @sizeOf(Element),
            };
        }
    };
}

fn isDevicePtr(comptime T: type) bool {
    if (@typeInfo(T) != .@"struct") return false;
    if (!@hasDecl(T, "info")) return false;
    return @TypeOf(T.info) == PointerInfo;
}

fn isDeviceSlice(comptime T: type) bool {
    if (@typeInfo(T) != .@"struct") return false;
    if (!@hasDecl(T, "info")) return false;
    return @TypeOf(T.info) == SliceInfo;
}

pub fn AllocationOne(Element: type, @"align": ?Alignment) type {
    const alignment = if (@"align") |a| a.toByteUnits() else @alignOf(Element);
    return struct {
        device: Ptr(.one, Element, .{ .@"align" = @"align" }),
        host: *align(alignment) Element,
    };
}

pub fn Allocation(Element: type, @"align": ?Alignment) type {
    const alignment = if (@"align") |a| a.toByteUnits() else @alignOf(Element);
    return struct {
        device_ptr: Ptr(.many, Element, .{ .@"align" = @"align" }),
        host_ptr: [*]align(alignment) Element,
        len: usize,

        pub const empty: @This() = .{
            .device_ptr = .empty,
            .host_ptr = &.{},
            .len = 0,
        };

        pub fn host(allocation: @This()) []align(alignment) Element {
            return allocation.host_ptr[0..allocation.len];
        }

        pub fn device(allocation: @This()) Slice(Element, .{ .@"align" = @"align" }) {
            return allocation.device_ptr.slice(allocation.len);
        }

        pub fn sliceStart(allocation: @This(), start: u64) Allocation(Element, null) {
            return .{
                .device_ptr = allocation.device_ptr.add(start),
                .host_ptr = allocation.host_ptr + start,
                .len = allocation.len - start,
            };
        }
    };
}

pub const DeviceAllocator = struct {
    pub const Error = error{
        OutOfDeviceMemory,
        OutOfMemory,
    };

    pub const BytePtr = Ptr(.many, u8, .{});
    pub const ByteSlice = Slice(u8, .{});

    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        alloc: *const fn (*anyopaque, size: usize, alignment: Alignment, memory_kind: sc.MemoryKind, ret_addr: usize) Error!sc.HostDeviceAddress,
        free: *const fn (*anyopaque, memory: ByteSlice, alignment: Alignment, memory_kind: sc.MemoryKind, ret_addr: usize) void,
    };

    pub fn noAlloc(
        context: *anyopaque,
        size: usize,
        alignment: Alignment,
        memory_kind: sc.MemoryKind,
        ret_addr: usize,
    ) Error!sc.HostDeviceAddress {
        _ = context;
        _ = size;
        _ = alignment;
        _ = memory_kind;
        _ = ret_addr;
        return error.OutOfDeviceMemory;
    }

    pub fn noFree(
        context: *anyopaque,
        memory: ByteSlice,
        alignment: Alignment,
        memory_kind: sc.MemoryKind,
        ret_addr: usize,
    ) void {
        _ = context;
        _ = memory;
        _ = alignment;
        _ = memory_kind;
        _ = ret_addr;
    }

    pub inline fn rawAlloc(a: DeviceAllocator, size: usize, alignment: Alignment, memory_kind: sc.MemoryKind, ret_addr: usize) Error!sc.HostDeviceAddress {
        return a.vtable.alloc(a.ptr, size, alignment, memory_kind, ret_addr);
    }

    pub inline fn rawFree(a: DeviceAllocator, memory: ByteSlice, alignment: Alignment, memory_kind: sc.MemoryKind, ret_addr: usize) void {
        return a.vtable.free(a.ptr, memory, alignment, memory_kind, ret_addr);
    }

    pub fn create(a: DeviceAllocator, comptime T: type, memory_kind: sc.MemoryKind) Error!AllocationOne(T, null) {
        if (@sizeOf(T) == 0) {
            return .{
                .device = .fromInt((Ptr(.one, T, .{}).alignment orelse .@"1").backward(std.math.maxInt(u64))),
                .host = @ptrFromInt(comptime std.mem.alignBackward(usize, std.math.maxInt(usize), @alignOf(T))),
            };
        }
        const result = try a.allocBytesWithAlignment(.of(T), @sizeOf(T), memory_kind, @returnAddress());
        return .{
            .device = .fromInt(result.device.addr),
            .host = @ptrCast(@alignCast(result.host)),
        };
    }

    pub fn destroy(device_allocator: DeviceAllocator, allocation: anytype, memory_kind: sc.MemoryKind) void {
        const info = @TypeOf(allocation).info;
        if (info.size != .one) @compileError("owned.device must be a single item device pointer");
        const T = info.Element;
        if (@sizeOf(T) == 0) return;
        device_allocator.rawFree(
            .{ .ptr = .{ .addr = allocation.addr }, .len = @sizeOf(T) },
            comptime info.attributes.@"align" orelse .of(T),
            memory_kind,
            @returnAddress(),
        );
    }

    pub fn alloc(device_allocator: DeviceAllocator, comptime T: type, n: usize, memory_kind: sc.MemoryKind) Error!Allocation(T, null) {
        return device_allocator.alignedAllocWithRetAddr(T, null, n, memory_kind, @returnAddress());
    }

    pub fn alignedAlloc(
        device_allocator: DeviceAllocator,
        comptime T: type,
        comptime alignment: ?Alignment,
        n: usize,
        memory_kind: sc.MemoryKind,
    ) Error!Allocation(T, alignment) {
        return device_allocator.alignedAllocWithRetAddr(T, alignment, n, memory_kind, @returnAddress());
    }

    pub fn runtimeAlignedAlloc(
        device_allocator: DeviceAllocator,
        comptime T: type,
        alignment: Alignment,
        n: usize,
        memory_kind: sc.MemoryKind,
    ) Error!Allocation(T, null) {
        return device_allocator.runtimeAlignedAllocWithRetAddr(T, alignment, n, memory_kind, @returnAddress());
    }

    pub inline fn alignedAllocWithRetAddr(
        device_allocator: DeviceAllocator,
        comptime T: type,
        comptime alignment: ?Alignment,
        n: usize,
        memory_kind: sc.MemoryKind,
        return_address: usize,
    ) Error!Allocation(T, alignment) {
        const a: Alignment = alignment orelse comptime .of(T);
        const owned = try device_allocator.runtimeAlignedAllocWithRetAddr(T, a, n, memory_kind, return_address);
        return .{ .device_ptr = .alignCast(owned.device_ptr), .host_ptr = @alignCast(owned.host_ptr), .len = owned.len };
    }

    pub inline fn runtimeAlignedAllocWithRetAddr(
        device_allocator: DeviceAllocator,
        comptime T: type,
        alignment: Alignment,
        n: usize,
        memory_kind: sc.MemoryKind,
        return_address: usize,
    ) Error!Allocation(T, null) {
        const byte_count = std.math.mul(usize, @sizeOf(T), n) catch return error.OutOfDeviceMemory;
        const result = try device_allocator.allocBytesWithAlignment(alignment, byte_count, memory_kind, return_address);
        const host_ptr: [*]T = @ptrCast(@alignCast(result.host));
        return .{
            .device_ptr = .fromInt(result.device.addr),
            .host_ptr = host_ptr,
            .len = n,
        };
    }

    fn allocBytesWithAlignment(
        device_allocator: DeviceAllocator,
        alignment: Alignment,
        byte_count: usize,
        memory_kind: sc.MemoryKind,
        return_address: usize,
    ) Error!sc.HostDeviceAddress {
        if (byte_count == 0) return .{
            .device = .{ .addr = alignment.backward(std.math.maxInt(u64)) },
            .host = @ptrFromInt(alignment.backward(std.math.maxInt(usize))),
        };
        return try device_allocator.rawAlloc(byte_count, alignment, memory_kind, return_address);
    }

    pub fn free(device_allocator: DeviceAllocator, allocation: anytype, memory_kind: sc.MemoryKind) void {
        const info = @TypeOf(allocation).info;
        const T = info.Element;
        const bytes = allocation.asBytes();
        if (bytes.len == 0) return;
        device_allocator.rawFree(
            .as(bytes),
            comptime info.attributes.@"align" orelse .of(T),
            memory_kind,
            @returnAddress(),
        );
    }

    pub fn runtimeAlignedFree(device_allocator: DeviceAllocator, allocation: anytype, alignment: Alignment, memory_kind: sc.MemoryKind) void {
        const bytes = allocation.asBytes();
        if (bytes.len == 0) return;
        device_allocator.rawFree(
            .as(bytes),
            alignment,
            memory_kind,
            @returnAddress(),
        );
    }

    pub const failing: DeviceAllocator = .{
        .ptr = undefined,
        .vtable = &.{
            .alloc = noAlloc,
            .free = unreachableFree,
        },
    };

    fn unreachableFree(
        context: *anyopaque,
        memory: ByteSlice,
        alignment: Alignment,
        memory_kind: sc.MemoryKind,
        ret_addr: usize,
    ) void {
        _ = context;
        _ = memory;
        _ = alignment;
        _ = memory_kind;
        _ = ret_addr;
        unreachable;
    }
};

pub fn rawDeviceAllocator(d: *sc.Device) DeviceAllocator {
    return .{
        .ptr = @ptrCast(d),
        .vtable = &.{
            .alloc = raw_device_allocator.alloc,
            .free = raw_device_allocator.free,
        },
    };
}

pub const raw_device_allocator = struct {
    pub fn alloc(
        context: *anyopaque,
        size: usize,
        alignment: std.mem.Alignment,
        memory_kind: sc.MemoryKind,
        ret_addr: usize,
    ) DeviceAllocator.Error!sc.HostDeviceAddress {
        _ = ret_addr;
        const device: *sc.Device = @ptrCast(@alignCast(context));
        return try device.alloc(size, alignment.toByteUnits(), memory_kind);
    }

    pub fn free(
        context: *anyopaque,
        memory: Slice(u8, .{}),
        alignment: std.mem.Alignment,
        memory_kind: sc.MemoryKind,
        ret_addr: usize,
    ) void {
        _ = alignment;
        _ = memory_kind;
        _ = ret_addr;
        const device: *sc.Device = @ptrCast(@alignCast(context));
        return device.free(.fromInt(memory.ptr.addr));
    }
};

pub const FixedBufferAllocator = struct {
    regions: std.EnumArray(sc.MemoryKind, Region),

    const Region = struct {
        buffer: Allocation(u8, null),
        end_index: u64,

        const empty: Region = .{ .buffer = .empty, .end_index = 0 };

        fn base(r: *const Region) u64 {
            return r.buffer.device_ptr.addr;
        }

        fn ownsAddr(r: *const Region, addr: u64) bool {
            return addr >= r.base() and addr < r.base() + r.buffer.len;
        }

        fn isLastAllocation(r: *const Region, memory: Slice(u8, .{})) bool {
            return memory.ptr.addr + memory.len == r.base() + r.end_index;
        }

        fn alloc(
            r: *Region,
            size: usize,
            alignment: std.mem.Alignment,
        ) DeviceAllocator.Error!sc.HostDeviceAddress {
            if (r.buffer.len == 0) return error.OutOfMemory;

            const addr = alignment.forward(r.base() + r.end_index);
            const start = addr - r.base();
            const end_new = std.math.add(u64, start, size) catch return error.OutOfMemory;
            if (end_new > r.buffer.len) return error.OutOfMemory;
            r.end_index = end_new;

            return .{
                .device = .fromInt(addr),
                .host = @ptrCast(r.buffer.host_ptr + start),
            };
        }

        fn resize(r: *Region, memory: Slice(u8, .{}), size_new: usize) bool {
            std.debug.assert(r.ownsAddr(memory.ptr.addr));
            if (!r.isLastAllocation(memory)) return size_new <= memory.len;
            if (size_new <= memory.len) {
                r.end_index -= memory.len - size_new;
                return true;
            }
            const grow = size_new - memory.len;
            if (r.end_index + grow > r.buffer.len) return false;
            r.end_index += grow;
            return true;
        }

        fn free(r: *Region, memory: Slice(u8, .{})) void {
            if (memory.len == 0) return;
            std.debug.assert(r.ownsAddr(memory.ptr.addr));
            if (r.isLastAllocation(memory)) r.end_index -= memory.len;
        }
    };

    pub fn init(buffers: std.EnumArray(sc.MemoryKind, Allocation(u8, null))) FixedBufferAllocator {
        var fba: FixedBufferAllocator = .{ .regions = .initFill(.empty) };
        for (std.enums.values(sc.MemoryKind)) |m| {
            fba.regions.getPtr(m).* = .{ .buffer = buffers.get(m), .end_index = 0 };
        }
        return fba;
    }

    pub fn initAlloc(
        gpa: DeviceAllocator,
        sizes: std.EnumArray(sc.MemoryKind, usize),
    ) DeviceAllocator.Error!FixedBufferAllocator {
        var fba: FixedBufferAllocator = .{ .regions = .initFill(.empty) };
        errdefer fba.deinit(gpa);
        for (std.enums.values(sc.MemoryKind)) |m| {
            fba.regions.getPtr(m).* = .{
                .buffer = try gpa.alloc(u8, sizes.get(m), m),
                .end_index = 0,
            };
        }
        return fba;
    }

    pub fn deinit(fba: *FixedBufferAllocator, gpa: DeviceAllocator) void {
        for (std.enums.values(sc.MemoryKind)) |m| {
            const buffer = &fba.regions.getPtr(m).buffer;
            if (buffer.len > 0) gpa.free(buffer.device(), m);
            buffer.* = .empty;
        }
    }

    pub fn reset(fba: *FixedBufferAllocator) void {
        for (&fba.regions.values) |*r| r.end_index = 0;
    }

    pub fn allocator(fba: *FixedBufferAllocator) DeviceAllocator {
        return .{
            .ptr = @ptrCast(fba),
            .vtable = &.{
                .alloc = alloc,
                .free = free,
            },
        };
    }

    fn alloc(
        context: *anyopaque,
        size: usize,
        alignment: std.mem.Alignment,
        memory_kind: sc.MemoryKind,
        ret_addr: usize,
    ) DeviceAllocator.Error!sc.HostDeviceAddress {
        _ = ret_addr;
        const fba: *FixedBufferAllocator = @ptrCast(@alignCast(context));
        return fba.regions.getPtr(memory_kind).alloc(size, alignment);
    }

    fn free(
        context: *anyopaque,
        memory: Slice(u8, .{}),
        alignment: std.mem.Alignment,
        memory_kind: sc.MemoryKind,
        ret_addr: usize,
    ) void {
        _ = alignment;
        _ = ret_addr;
        const fba: *FixedBufferAllocator = @ptrCast(@alignCast(context));
        fba.regions.getPtr(memory_kind).free(memory);
    }
};
