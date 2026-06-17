const std = @import("std");

const solver = @import("../solver.zig");
const testing = @import("../testing.zig");

const Parser = @import("../Parser.zig");

const Rect = struct {
    x1: u16,
    y1: u16,
    x2: u16,
    y2: u16,
};

fn solveInt(input: solver.Input, _: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var coverage: [1000][1000]u2 = .{.{0} ** 1000} ** 1000;

    var lines = input.lines();
    while (lines.next()) |line| {
        const rect = try parseRect(line);
        for (rect.y1..rect.y2) |y| {
            for (rect.x1..rect.x2) |x| {
                coverage[y][x] +|= 1;
            }
        }
    }

    var count: u32 = 0;
    for (coverage) |row| {
        for (row) |square| {
            if (square >= 2) count += 1;
        }
    }
    return .{ count, null };
}

pub const solve = solver.intSolver(u32, solveInt);

test "solve" {
    const input =
        \\#1 @ 1,3: 4x4
        \\#2 @ 3,1: 4x4
        \\#3 @ 5,5: 2x2
    ;
    try testing.expectIntSolution(u32, solveInt, .{ 4, null }, input);
}

fn parseRect(str: []const u8) Parser.Error!Rect {
    var parser: Parser = .init(str, .{});
    try parser.skipMany(2);
    const lspace = try parser.findInt(u16);
    const tspace = try parser.findInt(u16);
    const width = try parser.findInt(u16);
    const height = try parser.findInt(u16);

    return .{ .x1 = lspace, .y1 = tspace, .x2 = lspace + width, .y2 = tspace + height };
}
