const std = @import("std");

const solver = @import("../solver.zig");
const testing = @import("../testing.zig");

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?usize, ?usize } {
    const gpa = tools.gpa;
    var first_reduction: std.ArrayList(u8) = .empty;
    defer first_reduction.deinit(gpa);

    try reduce(gpa, try input.firstLine(), &first_reduction, 0);

    var second_reduction: std.ArrayList(u8) = .empty;
    defer second_reduction.deinit(gpa);

    var min_size: usize = std.math.maxInt(usize);
    for ('a'..'z') |unit| {
        try reduce(gpa, first_reduction.items, &second_reduction, @intCast(unit));
        min_size = @min(min_size, second_reduction.items.len);
    }

    return .{ first_reduction.items.len, min_size };
}

pub const solve = solver.intSolver(usize, solveInt);

test "solve" {
    const input = "dabAcCaCBAcCcaDA";
    try testing.expectIntSolution(usize, solveInt, .{ 10, 4 }, input);
}

fn reduce(gpa: std.mem.Allocator, polymer: []const u8, stack: *std.ArrayList(u8), unit: u8) error{OutOfMemory}!void {
    stack.clearRetainingCapacity();
    for (polymer) |char| {
        if (char == unit or char ^ 0b00100000 == unit) continue;

        if (stack.items.len > 0 and stack.items[stack.items.len - 1] == char ^ 0b00100000) {
            _ = stack.pop();
        } else {
            try stack.append(gpa, char);
        }
    }
}
