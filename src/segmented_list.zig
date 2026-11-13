const std = @import("std");

const min_exp = 8;
const max_shelve_count = 40 - min_exp;

const ShelfIndex = std.math.Log2Int(usize);

pub fn SegmentedList(comptime T: type) type {
    return struct {
        shelves: [max_shelve_count][*]T,
        len: usize,
        shelf_count: ShelfIndex,

        const Self = @This();

        pub const empty: Self = .{ .shelves = undefined, .len = 0, .shelf_count = 0 };

        pub fn deinit(list: *Self, allocator: std.mem.Allocator) void {
            for (0..list.shelf_count) |i| allocator.free(list.shelves[i][0..shelfLen(@intCast(i))]);
            list.* = undefined;
        }

        pub fn append(list: *Self, allocator: std.mem.Allocator, item: T) !void {
            (try list.addOne(allocator)).* = item;
        }

        pub fn pop(list: *Self) ?T {
            if (list.len == 0) return null;
            const item = list.at(list.len - 1).*;
            list.len -= 1;
            return item;
        }

        pub fn addOne(list: *Self, allocator: std.mem.Allocator) !*T {
            try list.ensureCapacity(allocator, list.len + 1);
            list.len += 1;
            return list.at(list.len - 1);
        }

        pub fn ensureCapacity(list: *Self, allocator: std.mem.Allocator, capacity: usize) !void {
            const old = list.shelf_count;
            const new = shelfCount(capacity);
            if (new <= old) return;
            var i: ShelfIndex = old;
            errdefer for (old..i) |j| allocator.free(list.shelves[j][0..shelfLen(@intCast(j))]);
            while (i < new) : (i += 1) list.shelves[i] = (try allocator.alloc(T, shelfLen(i))).ptr;
            list.shelf_count = new;
        }

        pub fn at(list: *const Self, index: usize) *T {
            std.debug.assert(index < list.len);
            const si = shelfIndex(index);
            return &list.shelves[si][boxIndex(index, si)];
        }
    };
}

pub fn shelfCount(count: usize) ShelfIndex {
    return @intCast(std.math.log2_int_ceil(usize, count + (1 << min_exp)) - min_exp);
}

pub fn shelfLen(shelf: ShelfIndex) usize {
    return @as(usize, 1) << (shelf + min_exp);
}

pub fn shelfIndex(index: usize) ShelfIndex {
    return std.math.log2_int(usize, index + (1 << min_exp)) - min_exp;
}

pub fn boxIndex(index: usize, shelf: ShelfIndex) usize {
    return index + (1 << min_exp) - (@as(usize, 1) << (shelf + min_exp));
}
