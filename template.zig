const std = @import("std");

const solver = @import("../solver.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    while (try tools.input.takeDelimiter('\n')) |line| {
        _ = line;
    }
    return .{ null, null };
}

pub const solve = solver.intSolver(u32, solveInt);
