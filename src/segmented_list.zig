const std = @import("std");

pub fn SegmentedList(comptime T: type) type {
    const min_exp = 8;
    const max_shelve_count = 40 - min_exp;

    return struct {
        const Self = @This();
        const ShelfIndex = std.math.Log2Int(usize);

        pub const empty: Self = .{ .shelves = undefined, .len = 0, .shelf_count = 0 };

        shelves: [max_shelve_count][*]T,
        len: usize,
        shelf_count: ShelfIndex,

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            for (0..self.shelf_count) |i| allocator.free(self.shelves[i][0..shelfLen(@intCast(i))]);
            self.* = undefined;
        }

        pub fn append(self: *Self, allocator: std.mem.Allocator, item: T) !void {
            (try self.addOne(allocator)).* = item;
        }

        pub fn pop(self: *Self) ?T {
            if (self.len == 0) return null;
            const item = self.uncheckedAt(self.len - 1).*;
            self.len -= 1;
            return item;
        }

        pub fn addOne(self: *Self, allocator: std.mem.Allocator) !*T {
            try self.ensureCapacity(allocator, self.len + 1);
            const result = self.uncheckedAt(self.len);
            self.len += 1;
            return result;
        }

        pub fn ensureCapacity(self: *Self, allocator: std.mem.Allocator, needed: usize) !void {
            const old = self.shelf_count;
            const new = shelfCount(needed);
            if (new <= old) return;
            var i: ShelfIndex = old;
            errdefer for (old..i) |j| allocator.free(self.shelves[j][0..shelfLen(@intCast(j))]);
            while (i < new) : (i += 1) self.shelves[i] = (try allocator.alloc(T, shelfLen(i))).ptr;
            self.shelf_count = new;
        }

        pub fn at(self: *const Self, index: usize) *T {
            std.debug.assert(index < self.len);
            return self.uncheckedAt(index);
        }

        fn uncheckedAt(self: *const Self, index: usize) *T {
            const si = shelfIndex(index);
            return &self.shelves[si][boxIndex(index, si)];
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
    };
}
