const std = @import("std");

const exp_min = 8;
const shelf_count_max = 40 - exp_min;

const ShelfIndex = std.math.Log2Int(usize);

pub fn SegmentedList(comptime T: type) type {
    return struct {
        shelves: [shelf_count_max][*]T,
        count: usize,
        shelf_count: ShelfIndex,

        const List = @This();

        pub const empty: List = .{ .shelves = undefined, .count = 0, .shelf_count = 0 };

        pub fn deinit(list: *List, allocator: std.mem.Allocator) void {
            for (0..list.shelf_count) |shelf_index| {
                allocator.free(list.shelves[shelf_index][0..shelfItemCount(@intCast(shelf_index))]);
            }
            list.* = undefined;
        }

        pub fn append(list: *List, allocator: std.mem.Allocator, item: T) !void {
            (try list.addOne(allocator)).* = item;
        }

        pub fn pop(list: *List) ?T {
            if (list.count == 0) return null;
            const item = list.at(list.count - 1).*;
            list.count -= 1;
            return item;
        }

        pub fn addOne(list: *List, allocator: std.mem.Allocator) !*T {
            try list.ensureCapacity(allocator, list.count + 1);
            list.count += 1;
            return list.at(list.count - 1);
        }

        pub fn ensureCapacity(list: *List, allocator: std.mem.Allocator, capacity: usize) !void {
            const shelf_count_old = list.shelf_count;
            const shelf_count_new: ShelfIndex = @intCast(std.math.log2_int_ceil(usize, capacity + (1 << exp_min)) - exp_min);
            if (shelf_count_new <= shelf_count_old) return;
            var shelf_index: ShelfIndex = shelf_count_old;
            errdefer for (shelf_count_old..shelf_index) |index| {
                allocator.free(list.shelves[index][0..shelfItemCount(@intCast(index))]);
            };
            while (shelf_index < shelf_count_new) : (shelf_index += 1) {
                list.shelves[shelf_index] = (try allocator.alloc(T, shelfItemCount(shelf_index))).ptr;
            }
            list.shelf_count = shelf_count_new;
        }

        pub fn at(list: *const List, index: usize) *T {
            std.debug.assert(index < list.count);
            const shelf_index = std.math.log2_int(usize, index + (1 << exp_min)) - exp_min;
            const shelf_item_index = index + (1 << exp_min) - (@as(usize, 1) << (shelf_index + exp_min));
            return &list.shelves[shelf_index][shelf_item_index];
        }
    };
}

fn shelfItemCount(shelf_index: ShelfIndex) usize {
    return @as(usize, 1) << (shelf_index + exp_min);
}
