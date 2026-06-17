const std = @import("std");

const solver = @import("../solver.zig");

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    _ = tools;
    while (try input.reader.takeDelimiter('\n')) |line| {
        _ = line;
    }
    return .{ null, null };
}

pub const solve = solver.intSolver(u32, solveInt);
