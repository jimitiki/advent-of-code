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

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    _ = tools;
    var sum_tls: u32 = 0;
    var sum_ssl: u32 = 0;
    while (try input.reader.takeDelimiter('\n')) |ip| {
        if (supportsTLS(ip) catch return error.InvalidInput) {
            sum_tls += 1;
        }
        if (supportsSSL(ip) catch return error.InvalidInput) {
            sum_ssl += 1;
        }
    }
    return .{ sum_tls, sum_ssl };
}

pub const solve = solver.intSolver(u32, solveInt);

fn supportsSSL(ip: []const u8) error{InvalidIP}!bool {
    var it: IPIterator = .{ .str = ip };
    while (it.nextSupernet()) |supernet| {
        if (supernet.len < 3) continue;
        for (0..supernet.len - 2) |i| {
            if (supernet[i] != supernet[i + 1] and supernet[i] == supernet[i + 2]) {
                if (try hasBAB(ip, supernet[i .. i + 3])) {
                    return true;
                }
            }
        }
    }
    return false;
}

test "ssl" {
    try std.testing.expect(try supportsSSL("aba[bab]xyz"));
    try std.testing.expect(!try supportsSSL("xyx[xyx]xyx"));
    try std.testing.expect(try supportsSSL("aaa[kek]eke"));
    try std.testing.expect(try supportsSSL("zazbz[bzb]cdb"));
}

fn hasBAB(ip: []const u8, aba: []const u8) error{InvalidIP}!bool {
    std.debug.assert(aba.len == 3);
    std.debug.assert(aba[0] == aba[2]);
    std.debug.assert(aba[0] != aba[1]);
    var it: IPIterator = .{ .str = ip };
    while (try it.nextHypernet()) |hypernet| {
        if (hypernet.len < 3) continue;
        for (0..hypernet.len - 2) |i| {
            const bab = hypernet[i .. i + 3];
            if (bab[0] == aba[1] and bab[1] == aba[0] and bab[2] == bab[0]) {
                return true;
            }
        }
    }
    return false;
}

test "bab" {
    try std.testing.expect(try hasBAB("aba[bab]xyz", "aba"));
    try std.testing.expect(!try hasBAB("aba[bab]xyz", "cbc"));
    try std.testing.expect(!try hasBAB("aba[bab]xyz", "bab"));
    try std.testing.expect(!try hasBAB("aba[aba]xyz", "aba"));
    try std.testing.expect(!try hasBAB("aba[aaa]xyz", "aba"));
    try std.testing.expect(!try hasBAB("aba[abc]xyz", "aba"));
}

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
