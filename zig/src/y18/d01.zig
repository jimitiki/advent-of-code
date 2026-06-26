const std = @import("std");
const lib = @import("lib");

const solver = lib.solver;
const testing = lib.testing;

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?i32, ?i32 } {
    var change_list: std.ArrayList(i32) = .empty;
    defer change_list.deinit(tools.gpa);

    var frequency: i32 = 0;
    var parser = input.parser(.{});
    while (try parser.parseInt(i32)) |n| {
        try change_list.append(tools.gpa, n);
        frequency += n;
    }

    var frequencies: std.AutoHashMapUnmanaged(i32, void) = .empty;
    defer frequencies.deinit(tools.gpa);

    var f: i32 = 0;
    var i: usize = 0;
    while (true) : (i = (i + 1) % change_list.items.len) {
        const change = change_list.items[i];
        f += change;
        const result = try frequencies.getOrPut(tools.gpa, f);
        if (result.found_existing) break;
    } else unreachable;

    return .{ frequency, f };
}

pub const solve = solver.intSolver(i32, solveInt);

test "solve" {
    try testing.expectIntSolution(i32, solveInt, .{ 3, 2 }, "+1\n-2\n+3\n+1");
    try testing.expectIntSolution(i32, solveInt, .{ 0, 1 }, "+1\n+1\n-2");
}
