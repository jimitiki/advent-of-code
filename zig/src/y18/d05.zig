const std = @import("std");

const solver = @import("../solver.zig");
const testing = @import("../testing.zig");

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?usize, ?usize } {
    var stack: std.ArrayList(u8) = .empty;
    defer stack.deinit(tools.gpa);
    for (try input.firstLine()) |char| {
        if (stack.items.len > 0 and stack.items[stack.items.len - 1] == char ^ 0b00100000) {
            _ = stack.pop();
        } else {
            try stack.append(tools.gpa, char);
        }
    }
    return .{ stack.items.len, null };
}

pub const solve = solver.intSolver(usize, solveInt);

test "solve" {
    const input = "dabAcCaCBAcCcaDA";
    try testing.expectIntSolution(usize, solveInt, .{ 10, null }, input);
}
