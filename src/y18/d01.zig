const std = @import("std");

const solver = @import("../solver.zig");
const testing = @import("../testing.zig");

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?i32, ?i32 } {
    _ = tools;
    var frequency: i32 = 0;
    while (try input.parser.parseInt(i32)) |n| {
        frequency += n;
    }
    return .{ frequency, null };
}

pub const solve = solver.intSolver(i32, solveInt);

test "solve" {
    try testing.expectIntSolution(i32, solveInt, .{ 3, null }, "+1\n-2\n+3\n+1");
    try testing.expectIntSolution(i32, solveInt, .{ 3, null }, "+1\n+1\n+1");
    try testing.expectIntSolution(i32, solveInt, .{ 0, null }, "+1\n+1\n-2");
    try testing.expectIntSolution(i32, solveInt, .{ -6, null }, "-1\n-2\n-3");
}
