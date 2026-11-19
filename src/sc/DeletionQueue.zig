const std = @import("std");
const DequeList = @import("deque_list.zig").DequeList;

const DeletionQueue = @This();

callbacks: DequeList(Callback),

pub const empty: DeletionQueue = .{ .callbacks = .empty };

const Callback = struct {
    function: *const fn (args: *align(args_alignment) const [args_capacity_bytes]u8) void,
    args: [args_capacity_bytes]u8 align(args_alignment),
    timeline_value: u64,

    const args_capacity_bytes = 128;
    const args_alignment = 16;
};

pub fn initCapacity(gpa: std.mem.Allocator, count: usize) !DeletionQueue {
    var queue: DeletionQueue = .empty;
    try queue.callbacks.ensureUnusedCapacity(gpa, count);
    return queue;
}

/// asserts that every callback has been flushed
pub fn deinit(queue: *DeletionQueue, gpa: std.mem.Allocator) void {
    std.debug.assert(queue.callbacks.len == 0);
    queue.callbacks.deinit(gpa);
    queue.* = undefined;
}

// args must be bellow 128 bytes and have a lower than 16 bytes alignement
pub fn push(
    queue: *DeletionQueue,
    gpa: std.mem.Allocator,
    timeline_value: u64,
    comptime function: anytype,
    args: std.meta.ArgsTuple(@TypeOf(function)),
) !void {
    const Args = @TypeOf(args);
    if (@sizeOf(Args) > Callback.args_capacity_bytes) @compileError("args size too large");
    if (@alignOf(Args) > Callback.args_alignment) @compileError("args alignement too large");
    if (queue.callbacks.first()) |newest| std.debug.assert(newest.timeline_value <= timeline_value);

    const local = struct {
        fn call(args_bytes: *align(Callback.args_alignment) const [Callback.args_capacity_bytes]u8) void {
            @call(.always_inline, function, @as(*const Args, @ptrCast(args_bytes)).*);
        }
    };
    var callback: Callback = .{ .function = local.call, .args = undefined, .timeline_value = timeline_value };
    @as(*Args, @ptrCast(&callback.args)).* = args;
    try queue.callbacks.pushFirst(gpa, callback);
}

pub fn flush(queue: *DeletionQueue, timeline_value: u64) void {
    while (queue.callbacks.last()) |oldest| {
        if (oldest.timeline_value > timeline_value) break;
        const callback = queue.callbacks.popLast().?;
        callback.function(&callback.args);
    }
}

test {
    const gpa = std.testing.allocator;
    var queue: DeletionQueue = try .initCapacity(gpa, 3);
    defer queue.deinit(gpa);

    const local = struct {
        fn append(order: *std.ArrayList(u32), id: u32) void {
            order.appendAssumeCapacity(id);
        }
    };
    var order_buffer: [8]u32 = undefined;
    var order: std.ArrayList(u32) = .initBuffer(&order_buffer);

    try queue.push(gpa, 1, local.append, .{ &order, 10 });
    try queue.push(gpa, 1, local.append, .{ &order, 11 });
    try queue.push(gpa, 2, local.append, .{ &order, 20 });
    try queue.push(gpa, 3, local.append, .{ &order, 30 });

    queue.flush(0);
    try std.testing.expectEqualSlices(u32, &.{}, order.items);
    queue.flush(2);
    try std.testing.expectEqualSlices(u32, &.{ 10, 11, 20 }, order.items);
    queue.flush(std.math.maxInt(u64));
    try std.testing.expectEqualSlices(u32, &.{ 10, 11, 20, 30 }, order.items);
}
