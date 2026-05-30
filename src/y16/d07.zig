const std = @import("std");

const solver = @import("../solver.zig");

fn solveInt(gpa: std.mem.Allocator, input: *std.Io.Reader) solver.Error!struct { ?u32, ?u32 } {
    var sum_valid: u32 = 0;
    while (try input.takeDelimiter('\n')) |ip| {
        if (supportsTLS(ip)) {
            sum_valid += 1;
        }
    }
    _ = gpa;
    return .{ sum_valid, null };
}

pub const solve = solver.intSolver(u32, solveInt);

fn supportsTLS(ip: []const u8) bool {
    var hypernet: bool = false;
    var abba: bool = false;
    for (ip[0 .. ip.len - 3], 0..) |char, i| {
        if (hypernet) {
            if (char == ']') {
                hypernet = false;
            } else if (isABBA(ip[i .. i + 4])) {
                return false;
            }
        } else {
            if (char == '[') {
                hypernet = true;
            } else {
                if (isABBA(ip[i .. i + 4])) {
                    abba = true;
                }
            }
        }
    }
    return abba;
}

test "tls" {
    try std.testing.expect(supportsTLS("abba[mnop]qrst"));
    try std.testing.expect(!supportsTLS("abcd[bddb]xyyx"));
    try std.testing.expect(!supportsTLS("aaaa[qwer]tyui"));
    try std.testing.expect(supportsTLS("ioxxoj[asdfgh]zxcvbn"));
}

fn isABBA(seq: []const u8) bool {
    std.debug.assert(seq.len == 4);
    return seq[0] != seq[1] and seq[0] == seq[3] and seq[1] == seq[2];
}

test "abba" {
    try std.testing.expect(isABBA("abba"));
    try std.testing.expect(isABBA("baab"));
    try std.testing.expect(!isABBA("baba"));
    try std.testing.expect(!isABBA("aaaa"));
    try std.testing.expect(!isABBA("aabb"));
}
