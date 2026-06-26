const std = @import("std");
const lib = @import("lib");

const solver = lib.solver;
const Parser = lib.Parser;

const KnotHasher = @import("KnotHasher.zig");

pub fn solve(input: solver.Input, tools: solver.Tools, p1buf: *[32]u8, p2buf: *[32]u8) solver.Error!solver.Result {
    var count: usize = 1;
    for (input.text) |char| {
        if (char == ',') count += 1;
    }
    const lengths = try tools.gpa.alloc(usize, count);
    defer tools.gpa.free(lengths);
    var parser: Parser = .init(input.text, .{});
    for (0..lengths.len) |i| {
        lengths[i] = try parser.takeInt(usize);
    }

    var hasher: KnotHasher = .init();
    for (lengths) |length| hasher.reverse(length);
    const p1_str = std.fmt.bufPrint(
        p1buf,
        "{}",
        .{@as(u16, hasher.buf[0]) * hasher.buf[1]},
    ) catch unreachable;

    hasher = .init();
    hasher.hashHex(input.text, p2buf);

    return .{ p1_str, p2buf };
}
