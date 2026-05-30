const std = @import("std");

const solver = @import("../solver.zig");

const IPIterator = struct {
    const Seq = union(enum) {
        supernet: []const u8,
        hypernet: []const u8,
    };

    str: []const u8,
    index: usize = 0,

    const Self = @This();

    pub fn next(self: *Self) error{InvalidIP}!?Seq {
        if (self.index >= self.str.len) {
            return null;
        }
        if (self.str[self.index] == '[') {
            return if (try self.nextHypernet()) |seq| .{ .hypernet = seq } else null;
        } else if (self.str[self.index] == ']' or self.index == 0) {
            return if (self.nextSupernet()) |seq| .{ .supernet = seq } else null;
        } else {
            return error.InvalidIP;
        }
    }

    pub fn nextSupernet(self: *Self) ?[]const u8 {
        while (self.index < self.str.len - 1) : (self.index += 1) {
            if (self.index == 0 and self.str[self.index] != '[' or self.str[self.index] == ']') break;
        } else return null;
        const start = self.index;
        while (self.index < self.str.len and self.str[self.index] != '[') : (self.index += 1) {}
        return self.str[start..self.index];
    }

    pub fn nextHypernet(self: *Self) error{InvalidIP}!?[]const u8 {
        while (self.index < self.str.len) : (self.index += 1) {
            if (self.str[self.index] == '[') break;
        } else return null;
        const start = self.index;
        while (self.index < self.str.len) : (self.index += 1) {
            if (self.str[self.index] == ']') break;
        } else return error.InvalidIP;
        return self.str[start..self.index];
    }
};

fn solveInt(gpa: std.mem.Allocator, input: *std.Io.Reader) solver.Error!struct { ?u32, ?u32 } {
    var sum_valid: u32 = 0;
    var sum_ssl: u32 = 0;
    while (try input.takeDelimiter('\n')) |ip| {
        if (supportsTLS(ip) catch return error.InvalidInput) {
            sum_valid += 1;
        }
    }
    _ = gpa;
    return .{ sum_valid, null };
}

pub const solve = solver.intSolver(u32, solveInt);

fn supportsTLS(ip: []const u8) error{InvalidIP}!bool {
    var abba: bool = false;
    var it: IPIterator = .{ .str = ip };
    while (try it.next()) |seq| {
        switch (seq) {
            .hypernet => |hypernet| if (hasABBA(hypernet)) {
                return false;
            },
            .supernet => |supernet| if (hasABBA(supernet)) {
                abba = true;
            },
        }
    }
    return abba;
}

test "tls" {
    try std.testing.expect(try supportsTLS("abba[mnop]qrst"));
    try std.testing.expect(!try supportsTLS("abcd[bddb]xyyx"));
    try std.testing.expect(!try supportsTLS("aaaa[qwer]tyui"));
    try std.testing.expect(try supportsTLS("ioxxoj[asdfgh]zxcvbn"));
}

fn hasABBA(seq: []const u8) bool {
    if (seq.len < 4) {
        return false;
    }
    for (0..seq.len - 3) |i| {
        const abba = seq[i .. i + 4];
        if (abba[0] != abba[1] and abba[0] == abba[3] and abba[1] == abba[2]) {
            return true;
        }
    }
    return false;
}

test "abba" {
    try std.testing.expect(hasABBA("aabbaaaaaaaaaaaaa"));
    try std.testing.expect(hasABBA("bbbbbbbbbbbaab"));
    try std.testing.expect(!hasABBA("baba"));
    try std.testing.expect(!hasABBA("aaaa"));
    try std.testing.expect(!hasABBA("aabb"));
}
