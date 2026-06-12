const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");
const t = @import("../test.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u64, ?u64 } {
    var a = try parseInput(tools.input);
    var b = try parseInput(tools.input);

    var matches: u64 = 0;
    for (0..40_000_000) |_| {
        a = (a * 16807) % 2147483647;
        b = (b * 48271) % 2147483647;
        if (@as(u16, @truncate(a)) == @as(u16, @truncate(b))) {
            matches += 1;
        }
    }
    return .{ matches, null };
}

pub const solve = solver.intSolver(u64, solveInt);

test "solve" {
    const input =
        \\Generator A starts with 65
        \\Generator B starts with 8921
    ;
    try t.expectIntSolution(u64, solveInt, .{ 588, null }, input);
}

fn parseInput(reader: *std.Io.Reader) solver.Error!u64 {
    const line = try reader.takeDelimiter('\n') orelse return error.InvalidInput;
    var parser: Parser = .init(line, .{});
    try parser.skipMany(4);
    return try parser.takeInt(u64);
}
