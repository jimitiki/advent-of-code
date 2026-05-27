const std = @import("std");
const solver = @import("../solver.zig");

fn solveInt(_: std.mem.Allocator, input: *std.Io.Reader) error{InvalidInput}!struct { ?i32, ?i32 } {
    var floor: i32 = 0;
    var pos: i32 = 1;
    var answer: ?i32 = null;
    while (true) : (pos += 1) {
        const c = input.takeByte() catch break;
        switch (c) {
            '(' => floor += 1,
            ')' => floor -= 1,
            '\n' => break,
            else => return error.InvalidInput,
        }
        if (floor < 0) {
            answer = answer orelse pos;
        }
    }
    return .{ floor, answer };
}

pub const solve = solver.intSolver(i32, solveInt);
