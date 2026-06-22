const std = @import("std");

const solver = @import("../solver.zig");
const testing = @import("../testing.zig");

const Parser = @import("../Parser.zig");

const Edge = struct { parent: u8, child: u8 };
const EdgeList = std.ArrayList(Edge);
const StepSet = std.AutoHashMapUnmanaged(u8, void);

pub fn solve(input: solver.Input, tools: solver.Tools, p1buf: *[32]u8, p2buf: *[32]u8) solver.Error!solver.Result {
    _ = p2buf;
    const gpa = tools.gpa;
    var edge_list = try parse(gpa, input);
    defer edge_list.deinit(gpa);

    const steps = try getStepsSorted(gpa, edge_list.items);
    defer gpa.free(steps);

    return .{ try computeOrder(gpa, p1buf, steps, edge_list.items), null };
}

test "solve" {
    const input =
        \\Step C must be finished before step A can begin.
        \\Step C must be finished before step F can begin.
        \\Step A must be finished before step B can begin.
        \\Step A must be finished before step D can begin.
        \\Step B must be finished before step E can begin.
        \\Step D must be finished before step E can begin.
        \\Step F must be finished before step E can begin.
    ;
    try testing.expectSolution(solve, .{ "CABDFE", null }, input);
}

fn parse(gpa: std.mem.Allocator, input: solver.Input) solver.Error!EdgeList {
    var edges: EdgeList = .empty;
    var lines = input.lines();
    while (lines.next()) |line| {
        var parser: Parser = .init(line, .{});
        try parser.skip();
        const parent = try parser.takeByte();
        try parser.skipMany(5);
        const child = try parser.takeByte();
        try edges.append(gpa, .{ .parent = parent, .child = child });
    }
    return edges;
}

fn getStepsSorted(gpa: std.mem.Allocator, edges: []const Edge) error{OutOfMemory}![]const u8 {
    var set: StepSet = .empty;
    defer set.deinit(gpa);

    for (edges) |edge| {
        try set.put(gpa, edge.parent, {});
        try set.put(gpa, edge.child, {});
    }

    const sorted = try gpa.alloc(u8, set.size);
    var it = set.keyIterator();
    var i: usize = 0;
    while (it.next()) |key_ptr| : (i += 1) {
        sorted[i] = key_ptr.*;
    }
    std.mem.sortUnstable(u8, sorted, {}, std.sort.asc(u8));
    return sorted;
}

fn computeOrder(gpa: std.mem.Allocator, buf: []u8, steps: []const u8, edges: []const Edge) error{OutOfMemory}!?[]const u8 {
    var used: StepSet = .empty;
    defer used.deinit(gpa);
    try used.ensureTotalCapacity(gpa, @intCast(steps.len));

    for (0..steps.len) |i| {
        const next_step = for (steps) |step| {
            if (used.contains(step)) continue;
            for (edges) |edge| {
                if (!used.contains(edge.parent) and edge.child == step) {
                    break;
                }
            } else break step;
        } else return null;
        buf[i] = next_step;
        used.putAssumeCapacity(next_step, {});
    }
    return buf[0..steps.len];
}
