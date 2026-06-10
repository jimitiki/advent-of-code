const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

const KnotHasher = struct {
    const Self = @This();

    buf: []u8,
    index: usize = 0,
    skip_size: usize = 0,

    pub fn reverse(self: *Self, amount: usize) void {
        std.debug.assert(amount <= self.buf.len);
        var a = self.index;
        var b = a + amount - 1;
        while (a < b) : ({
            a += 1;
            b -= 1;
        }) {
            const temp = self.buf[self.bufIndex(a)];
            self.buf[self.bufIndex(a)] = self.buf[self.bufIndex(b)];
            self.buf[self.bufIndex(b)] = temp;
        }
        self.index = self.bufIndex(self.index + amount + self.skip_size);
        self.skip_size += 1;
    }

    fn bufIndex(self: Self, index: usize) usize {
        if (index >= self.buf.len) {
            return index - self.buf.len;
        } else {
            return index;
        }
    }
};

test "hasher" {
    var buf: [5]u8 = .{ 0, 1, 2, 3, 4 };
    var hasher: KnotHasher = .{ .buf = &buf };
    hasher.reverse(3);
    try std.testing.expectEqual([_]u8{ 2, 1, 0, 3, 4 }, buf);
    try std.testing.expectEqual(3, hasher.index);
    try std.testing.expectEqual(1, hasher.skip_size);
    hasher.reverse(4);
    try std.testing.expectEqual([_]u8{ 4, 3, 0, 1, 2 }, buf);
    try std.testing.expectEqual(3, hasher.index);
    try std.testing.expectEqual(2, hasher.skip_size);
    hasher.reverse(1);
    try std.testing.expectEqual([_]u8{ 4, 3, 0, 1, 2 }, buf);
    try std.testing.expectEqual(1, hasher.index);
    try std.testing.expectEqual(3, hasher.skip_size);
    hasher.reverse(5);
    try std.testing.expectEqual([_]u8{ 3, 4, 2, 1, 0 }, buf);
    try std.testing.expectEqual(4, hasher.index);
    try std.testing.expectEqual(4, hasher.skip_size);
}

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    const input = try tools.input.takeDelimiter('\n') orelse return error.InvalidInput;
    var count: usize = 1;
    for (input) |char| {
        if (char == ',') count += 1;
    }
    const lengths = try tools.gpa.alloc(usize, count);
    defer tools.gpa.free(lengths);
    var parser: Parser = .init(input, .{});
    for (0..lengths.len) |i| {
        lengths[i] = try parser.takeInt(usize);
    }

    var numbers: [256]u8 = undefined;
    for (0..numbers.len) |i| numbers[i] = @intCast(i);

    var hasher: KnotHasher = .{ .buf = &numbers };
    for (lengths) |length| hasher.reverse(length);

    return .{ @as(u16, numbers[0]) * numbers[1], null };
}

pub const solve = solver.intSolver(u16, solveInt);
