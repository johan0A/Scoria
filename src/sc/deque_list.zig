const std = @import("std");

pub fn DequeList(T: type) type {
    return struct {
        buffer: []T,
        head: usize,
        len: usize,

        const Self = @This();

        pub const empty: Self = .{ .buffer = &.{}, .head = 0, .len = 0 };

        pub fn deinit(deque: *Self, gpa: std.mem.Allocator) void {
            gpa.free(deque.buffer);
            deque.* = undefined;
        }

        pub fn pushFirst(deque: *Self, gpa: std.mem.Allocator, item: T) !void {
            try deque.ensureUnusedCapacity(gpa, 1);
            deque.pushFirstAssumeCapacity(item);
        }

        pub fn pushFirstAssumeCapacity(deque: *Self, item: T) void {
            std.debug.assert(deque.len < deque.buffer.len);
            const tail = (deque.head + deque.len) & (deque.buffer.len - 1);
            deque.buffer[tail] = item;
            deque.len += 1;
        }

        pub fn pushLast(deque: *Self, gpa: std.mem.Allocator, item: T) !void {
            try deque.ensureUnusedCapacity(gpa, 1);
            deque.pushLastAssumeCapacity(item);
        }

        pub fn ensureUnusedCapacity(deque: *Self, gpa: std.mem.Allocator, count: usize) !void {
            const capacity_min = deque.len + count;
            if (capacity_min <= deque.buffer.len) return;
            const old_capacity = deque.buffer.len;
            const new_capacity = @max(try std.math.ceilPowerOfTwo(usize, capacity_min), 8);
            deque.buffer = try gpa.realloc(deque.buffer, new_capacity);

            const tail_len = (deque.head + deque.len) -| old_capacity;
            const head_len = deque.len - tail_len;
            if (tail_len <= head_len) {
                @memcpy(deque.buffer[old_capacity..][0..tail_len], deque.buffer[0..tail_len]);
            } else {
                const head_new = new_capacity - head_len;
                @memcpy(deque.buffer[head_new..][0..head_len], deque.buffer[deque.head..][0..head_len]);
                deque.head = head_new;
            }
        }

        pub fn pushLastAssumeCapacity(deque: *Self, item: T) void {
            std.debug.assert(deque.len < deque.buffer.len);
            deque.head = (deque.head -% 1) & (deque.buffer.len - 1);
            deque.buffer[deque.head] = item;
            deque.len += 1;
        }

        pub fn popFirst(deque: *Self) ?T {
            if (deque.len == 0) return null;
            deque.len -= 1;
            return deque.buffer[(deque.head + deque.len) & (deque.buffer.len - 1)];
        }

        pub fn popLast(deque: *Self) ?T {
            if (deque.len == 0) return null;
            const item = deque.buffer[deque.head];
            deque.head = (deque.head + 1) & (deque.buffer.len - 1);
            deque.len -= 1;
            return item;
        }

        pub fn first(deque: Self) ?*T {
            return if (deque.len == 0) null else deque.at(0);
        }

        pub fn last(deque: Self) ?*T {
            return if (deque.len == 0) null else deque.at(deque.len - 1);
        }

        /// index 0 is the first item
        pub fn at(deque: Self, index: usize) *T {
            std.debug.assert(index < deque.len);
            return &deque.buffer[(deque.head + deque.len - 1 - index) & (deque.buffer.len - 1)];
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
    try std.testing.expectEqual(40, deque.len);
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
