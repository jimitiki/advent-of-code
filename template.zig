const std = @import("std");

const solver = @import("../solver.zig");

fn solveInt(gpa: std.mem.Allocator, input: *std.Io.Reader) solver.Error!struct { ?u32, ?u32 } {
    _ = gpa;
    _ = input;
    return .{ null, null };
}

pub const solve = solver.intSolver(u32, solveInt);
