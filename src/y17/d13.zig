const std = @import("std");

const solver = @import("../solver.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var severity: u32 = 0;
    while (try tools.input.takeDelimiter('\n')) |line| {
        for (line, 0..) |char, i| {
            if (char == ':') {
                const depth = std.fmt.parseUnsigned(u32, line[0..i], 10) catch return error.InvalidInput;
                const range = std.fmt.parseUnsigned(u32, line[i + 2 ..], 10) catch return error.InvalidInput;
                if (depth % ((range - 1) * 2) == 0) {
                    severity += depth * range;
                }
                break;
            }
        }
    }
    return .{ severity, null };
}

pub const solve = solver.intSolver(u32, solveInt);
