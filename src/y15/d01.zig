const std = @import("std");
const solver = @import("../solver.zig");
const testing = @import("../testing.zig");

fn solveInt(input: solver.Input, tools: solver.Tools) error{InvalidInput}!struct { ?i32, ?i32 } {
    _ = tools;
    var floor: i32 = 0;
    var answer: ?i32 = null;
    for (input.text, 0..) |char, i| {
        switch (char) {
            '(' => floor += 1,
            ')' => floor -= 1,
            '\n' => break,
            else => return error.InvalidInput,
        }
        if (floor < 0) {
            answer = answer orelse @intCast(i + 1);
        }
    }
    return .{ floor, answer };
}

pub const solve = solver.intSolver(i32, solveInt);

test "solve" {
    testing.expectIntSolution(i32, solveInt, .{ 3, null }, "(((");
    testing.expectIntSolution(i32, solveInt, .{ 3, 1 }, "))(((((");
    testing.expectIntSolution(i32, solveInt, .{ -1, 5 }, "()())");
    testing.expectIntSolution(i32, solveInt, .{ -9, 5 }, "()())))))))))");
}
