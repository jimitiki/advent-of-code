const std = @import("std");

const solver = @import("../solver.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var offsets: std.ArrayList(i16) = .empty;
    defer offsets.deinit(tools.gpa);
    while (try tools.input.takeDelimiter('\n')) |line| {
        try offsets.append(tools.gpa, std.fmt.parseInt(i16, line, 10) catch return error.InvalidInput);
    }
    var pc: u32 = 0;
    var jumps: u32 = 0;
    while (pc < offsets.items.len) : (jumps += 1) {
        const offset = offsets.items[pc];
        offsets.items[pc] += 1;
        pc = @intCast(@as(i32, @intCast(pc)) + offset);
    }
    return .{ jumps, null };
}

pub const solve = solver.intSolver(u32, solveInt);
