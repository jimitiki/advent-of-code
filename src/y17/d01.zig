const std = @import("std");

const solver = @import("../solver.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    var sum: u16 = 0;
    const first = if (tools.input.takeByte()) |d| d - 48 else |_| return error.InvalidInput;
    var last = first;
    while (true) {
        const digit = tools.input.takeByte() catch break;
        if (digit < '0' or digit > '9') break;

        const next = digit - 48;
        if (next == last) {
            sum += next;
        }
        last = next;
    }
    if (last == first) {
        sum += first;
    }
    return .{ sum, null };
}

pub const solve = solver.intSolver(u16, solveInt);
