const std = @import("std");

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

pub fn hash(self: *Self, data: []const u8, digest: *[16]u8) void {
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
        digest[i] = dense;
    }
}

test "hash" {
    var digest: [16]u8 = undefined;
    var hasher: Self = .init();
    hasher.hash("", &digest);
    try std.testing.expectEqual(
        [_]u8{ 0xa2, 0x58, 0x2a, 0x3a, 0x0e, 0x66, 0xe6, 0xe8, 0x6e, 0x38, 0x12, 0xdc, 0xb6, 0x72, 0xa2, 0x72 },
        digest,
    );
    hasher = .init();
    hasher.hash("AoC 2017", &digest);
    try std.testing.expectEqual(
        [_]u8{ 0x33, 0xef, 0xeb, 0x34, 0xea, 0x91, 0x90, 0x2b, 0xb2, 0xf5, 0x9c, 0x99, 0x20, 0xca, 0xa6, 0xcd },
        digest,
    );
    hasher = .init();
    hasher.hash("1,2,3", &digest);
    try std.testing.expectEqual(
        [_]u8{ 0x3e, 0xfb, 0xe7, 0x8a, 0x8d, 0x82, 0xf2, 0x99, 0x79, 0x03, 0x1a, 0x4a, 0xa0, 0xb1, 0x6a, 0x9d },
        digest,
    );
    hasher = .init();
    hasher.hash("1,2,4", &digest);
    try std.testing.expectEqual(
        [_]u8{ 0x63, 0x96, 0x08, 0x35, 0xbc, 0xdc, 0x13, 0x0f, 0x0b, 0x66, 0xd7, 0xff, 0x4f, 0x6a, 0x5a, 0x8e },
        digest,
    );
}

pub fn hashHex(self: *Self, data: []const u8, hex_digest: *[32]u8) void {
    var digest: [16]u8 = undefined;
    self.hash(data, &digest);

    for (digest, 0..) |byte, i| {
        const index = i * 2;
        hex_digest[index] = std.fmt.hex_charset[byte >> 4];
        hex_digest[index + 1] = std.fmt.hex_charset[byte & 0x0f];
    }
}

test "hashHex" {
    var digest: [32]u8 = undefined;
    var hasher: Self = .init();
    hasher.hashHex("", &digest);
    try std.testing.expectEqualSlices(u8, "a2582a3a0e66e6e86e3812dcb672a272", &digest);
    hasher = .init();
    hasher.hashHex("AoC 2017", &digest);
    try std.testing.expectEqualSlices(u8, "33efeb34ea91902bb2f59c9920caa6cd", &digest);
    hasher = .init();
    hasher.hashHex("1,2,3", &digest);
    try std.testing.expectEqualSlices(u8, "3efbe78a8d82f29979031a4aa0b16a9d", &digest);
    hasher = .init();
    hasher.hashHex("1,2,4", &digest);
    try std.testing.expectEqualSlices(u8, "63960835bcdc130f0b66d7ff4f6a5a8e", &digest);
}

pub fn reverse(self: *Self, amount: usize) void {
    std.debug.assert(amount <= self.buf.len);
    var a = self.index;
    var b = a + amount - 1;
    while (a < b) : ({
        a += 1;
        b -= 1;
    }) {
        const ia = self.bufIndex(a);
        const ib = self.bufIndex(b);
        const temp = self.buf[ia];
        self.buf[ia] = self.buf[ib];
        self.buf[ib] = temp;
    }
    self.index = self.bufIndex(self.index + amount + self.skip_size);
    self.skip_size = if (self.skip_size == self.buf.len - 1) 0 else self.skip_size + 1;
}

fn bufIndex(self: Self, index: usize) usize {
    return index % self.buf.len;
}
