const std = @import("std");
const solver = @import("../solver.zig");

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
