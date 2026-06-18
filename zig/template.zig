const std = @import("std");

const solver = @import("../solver.zig");
const testing = @import("../testing.zig");

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    _ = tools;

    _ = input.firstLine();

    var parser = input.parser(.{});
    _ = parser.takeInt(u32);

    var lines = input.lines();
    while (lines.next()) |line| {
        _ = line;
    }

    return .{ null, null };
}

pub const solve = solver.intSolver(u32, solveInt);
