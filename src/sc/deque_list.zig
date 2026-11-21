const std = @import("std");

pub fn DequeList(T: type) type {
    return struct {
        buffer: []T,
        head: usize,
        count: usize,

        const Deque = @This();

        pub const empty: Deque = .{ .buffer = &.{}, .head = 0, .count = 0 };

        pub fn deinit(deque: *Deque, gpa: std.mem.Allocator) void {
            gpa.free(deque.buffer);
            deque.* = undefined;
        }

        pub fn pushFirst(deque: *Deque, gpa: std.mem.Allocator, item: T) !void {
            try deque.ensureUnusedCapacity(gpa, 1);
            deque.pushFirstAssumeCapacity(item);
        }

        pub fn pushFirstAssumeCapacity(deque: *Deque, item: T) void {
            std.debug.assert(deque.count < deque.buffer.len);
            const tail = (deque.head + deque.count) & (deque.buffer.len - 1);
            deque.buffer[tail] = item;
            deque.count += 1;
        }

        pub fn pushLast(deque: *Deque, gpa: std.mem.Allocator, item: T) !void {
            try deque.ensureUnusedCapacity(gpa, 1);
            deque.pushLastAssumeCapacity(item);
        }

        pub fn ensureUnusedCapacity(deque: *Deque, gpa: std.mem.Allocator, count: usize) !void {
            const capacity_min = deque.count + count;
            if (capacity_min <= deque.buffer.len) return;
            const capacity_old = deque.buffer.len;
            const capacity_new = @max(try std.math.ceilPowerOfTwo(usize, capacity_min), 8);
            deque.buffer = try gpa.realloc(deque.buffer, capacity_new);

            const tail_count = (deque.head + deque.count) -| capacity_old;
            const head_count = deque.count - tail_count;
            if (tail_count <= head_count) {
                @memcpy(deque.buffer[capacity_old..][0..tail_count], deque.buffer[0..tail_count]);
            } else {
                const head_new = capacity_new - head_count;
                @memcpy(deque.buffer[head_new..][0..head_count], deque.buffer[deque.head..][0..head_count]);
                deque.head = head_new;
            }
        }

        pub fn pushLastAssumeCapacity(deque: *Deque, item: T) void {
            std.debug.assert(deque.count < deque.buffer.len);
            deque.head = (deque.head -% 1) & (deque.buffer.len - 1);
            deque.buffer[deque.head] = item;
            deque.count += 1;
        }

        pub fn popFirst(deque: *Deque) ?T {
            if (deque.count == 0) return null;
            deque.count -= 1;
            return deque.buffer[(deque.head + deque.count) & (deque.buffer.len - 1)];
        }

        pub fn popLast(deque: *Deque) ?T {
            if (deque.count == 0) return null;
            const item = deque.buffer[deque.head];
            deque.head = (deque.head + 1) & (deque.buffer.len - 1);
            deque.count -= 1;
            return item;
        }

        pub fn first(deque: Deque) ?*T {
            return if (deque.count == 0) null else deque.at(0);
        }

        pub fn last(deque: Deque) ?*T {
            return if (deque.count == 0) null else deque.at(deque.count - 1);
        }

        /// Index 0 is the first item.
        pub fn at(deque: Deque, index: usize) *T {
            std.debug.assert(index < deque.count);
            return &deque.buffer[(deque.head + deque.count - 1 - index) & (deque.buffer.len - 1)];
        }
    };
}

test DequeList {
    const gpa = std.testing.allocator;
    var deque: DequeList(u32) = .empty;
    defer deque.deinit(gpa);

    var pushed_count: u32 = 0;
    var popped_count: u32 = 0;
    for (0..20) |_| {
        for (0..5) |_| {
            try deque.pushFirst(gpa, pushed_count);
            pushed_count += 1;
        }
        for (0..3) |_| {
            try std.testing.expectEqual(popped_count, deque.popLast().?);
            popped_count += 1;
        }
    }
    while (deque.popLast()) |item| {
        try std.testing.expectEqual(popped_count, item);
        popped_count += 1;
    }
    try std.testing.expectEqual(pushed_count, popped_count);
}

test "both ends" {
    const gpa = std.testing.allocator;
    var deque: DequeList(u32) = .empty;
    defer deque.deinit(gpa);

    for (0..20) |i| try deque.pushLast(gpa, @intCast(i));
    for (0..20) |i| try deque.pushFirst(gpa, @intCast(100 + i));
    try std.testing.expectEqual(40, deque.count);
    try std.testing.expectEqual(119, deque.first().?.*);
    try std.testing.expectEqual(19, deque.last().?.*);
    try std.testing.expectEqual(100, deque.at(19).*);
    try std.testing.expectEqual(0, deque.at(20).*);

    for (0..20) |i| try std.testing.expectEqual(119 - i, deque.popFirst().?);
    for (0..20) |i| try std.testing.expectEqual(i, deque.popFirst().?);
    try std.testing.expectEqual(null, deque.popFirst());
    try std.testing.expectEqual(null, deque.popLast());
    try std.testing.expectEqual(null, deque.first());
}
