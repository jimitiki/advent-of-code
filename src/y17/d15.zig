const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");
const t = @import("../test.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u64, ?u64 } {
    const astart = try parseInput(tools.input);
    const bstart = try parseInput(tools.input);

    var a = astart;
    var b = bstart;
    var matches: u64 = 0;
    for (0..40_000_000) |_| {
        a = a * 16807 % 2147483647;
        b = b * 48271 % 2147483647;
        if (@as(u16, @truncate(a)) == @as(u16, @truncate(b))) {
            matches += 1;
        }
    }

    a = astart;
    b = bstart;
    var matches_strict: u64 = 0;
    for (0..5_000_000) |_| {
        a = a * 16807 % 2147483647;
        b = b * 48271 % 2147483647;
        while (a & 0b11 != 0) : (a = a * 16807 % 2147483647) {}
        while (b & 0b111 != 0) : (b = b * 48271 % 2147483647) {}
        if (@as(u16, @truncate(a)) == @as(u16, @truncate(b))) {
            matches_strict += 1;
        }
    }
    return .{ matches, matches_strict };
}

pub const solve = solver.intSolver(u64, solveInt);

// Too slow to run with the rest of the tests
test "solve" {
    const input =
        \\Generator A starts with 65
        \\Generator B starts with 8921
    ;
    try t.expectIntSolution(u64, solveInt, .{ 588, 309 }, input);
}

fn parseInput(reader: *std.Io.Reader) solver.Error!u64 {
    const line = try reader.takeDelimiter('\n') orelse return error.InvalidInput;
    var parser: Parser = .init(line, .{});
    try parser.skipMany(4);
    return try parser.takeInt(u64);
}
