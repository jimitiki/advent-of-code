const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn Counter(T: type) type {
    return struct {
        const Self = @This();
        const Map = std.array_hash_map.Auto(T, usize);

        map: Map = .empty,

        pub const empty: Self = .{};
        const Oom = Allocator.Error;

        const SortContext = struct {
            counter: *const Self,

            pub fn lessThan(self: SortContext, a_index: usize, b_index: usize) bool {
                const a_entry = self.counter.map.entries.get(a_index);
                const b_entry = self.counter.map.entries.get(b_index);
                return a_entry.value > b_entry.value or (a_entry.value == b_entry.value and a_entry.key < b_entry.key);
            }
        };

        pub fn deinit(self: *Self, gpa: Allocator) void {
            self.map.deinit(gpa);
        }

        /// Creates a counter which stores the counts for each unique entry in `items`
        pub fn initSlice(gpa: Allocator, items: []const T) Oom!Self {
            var counter: Self = .empty;
            for (items) |item| {
                _ = try counter.add(gpa, item);
            }
            return counter;
        }

        /// Adds an item with a count of zero
        pub fn insert(self: *Self, gpa: Allocator, item: T) Oom!void {
            if (self.map.get(item)) {
                return;
            } else {
                try self.map.putNoClobber(gpa, item, 0);
            }
        }

        /// Increments the item's count. Sets the count to one if the item is new
        pub fn add(self: *Self, gpa: Allocator, item: T) Oom!usize {
            const result = try self.map.getOrPutValue(gpa, item, 0);
            result.value_ptr.* += 1;
            return result.value_ptr.*;
        }

        /// Increments the item's count. The caller guarantees that the item is already in the counter
        pub fn addExisting(self: *Self, item: T) usize {
            self.map.getEntry(item).?.value_ptr.* += 1;
        }

        /// Returns the top `n` keys in sorted order. Keys are sorted by:
        ///
        /// - count first (descending)
        /// - key second (ascending)
        ///
        /// This function modifies the order in which the counter entries are stored.
        pub fn topKeys(self: *Self, n: usize) []T {
            self.map.sortUnstable(SortContext{ .counter = self });
            return self.map.keys()[0..@min(n, self.map.entries.len)];
        }

        /// Returns the entry with the hightest count in the counter
        pub fn max(self: Self) struct { T, usize } {
            var max_val: usize = 0;
            var max_key: T = undefined;
            for (self.map.keys()) |k| {
                const v = self.map.get(k).?;
                if (v > max_val) {
                    max_val = v;
                    max_key = k;
                }
            }
            return .{ max_key, max_val };
        }

        /// Returns the entry with the lowest count in the counter
        pub fn min(self: Self) struct { T, usize } {
            var min_val: usize = std.math.maxInt(usize);
            var min_key: T = undefined;
            for (self.map.keys()) |k| {
                const v = self.map.get(k).?;
                if (v < min_val) {
                    min_val = v;
                    min_key = k;
                }
            }
            return .{ min_key, min_val };
        }
    };
}
