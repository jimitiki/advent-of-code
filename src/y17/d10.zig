const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

const KnotHasher = struct {
    const Self = @This();
    const suffix: [5]u8 = .{ 17, 31, 73, 47, 23 };

    buf: [256]u8,
    index: usize = 0,
    skip_size: usize = 0,

    pub fn init() Self {
        var buf: [256]u8 = undefined;
        var i: u8 = 0;
        while (true) : (i += 1) {
            buf[i] = i;
            if (i == 255) break;
        }
        return .{ .buf = buf };
    }

    pub fn hash(self: *Self, data: []const u8, digest: *[32]u8) void {
        for (0..64) |_| {
            for (data) |length| {
                self.reverse(length);
            }
            for (suffix) |length| {
                self.reverse(length);
            }
        }
        for (0..16) |i| {
            const buf_index = i * 16;
            var dense: u8 = 0;
            for (self.buf[buf_index .. buf_index + 16]) |byte| dense ^= byte;
            const digest_index = i * 2;
            digest[digest_index] = std.fmt.hex_charset[dense >> 4];
            digest[digest_index + 1] = std.fmt.hex_charset[dense & 0x0f];
        }
    }

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
        self.skip_size = if (self.skip_size == self.buf.len - 1) 0 else self.skip_size + 1;
    }

    fn bufIndex(self: Self, index: usize) usize {
        return index % self.buf.len;
    }
};

test "hash" {
    var digest: [32]u8 = undefined;
    var hasher: KnotHasher = .init();
    hasher.hash("", &digest);
    try std.testing.expectEqualSlices(u8, "a2582a3a0e66e6e86e3812dcb672a272", &digest);
    hasher = .init();
    hasher.hash("AoC 2017", &digest);
    try std.testing.expectEqualSlices(u8, "33efeb34ea91902bb2f59c9920caa6cd", &digest);
    hasher = .init();
    hasher.hash("1,2,3", &digest);
    try std.testing.expectEqualSlices(u8, "3efbe78a8d82f29979031a4aa0b16a9d", &digest);
    hasher = .init();
    hasher.hash("1,2,4", &digest);
    try std.testing.expectEqualSlices(u8, "63960835bcdc130f0b66d7ff4f6a5a8e", &digest);
}

pub fn solve(tools: solver.Tools) solver.Error!solver.Result {
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

    var hasher: KnotHasher = .init();
    for (lengths) |length| hasher.reverse(length);
    const p1_str = std.fmt.bufPrint(
        tools.p1buf,
        "{}",
        .{@as(u16, hasher.buf[0]) * hasher.buf[1]},
    ) catch unreachable;

    hasher = .init();
    hasher.hash(input, tools.p2buf);

    return .{ p1_str, tools.p2buf };
}
