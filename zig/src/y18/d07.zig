const std = @import("std");

const solver = @import("../solver.zig");
const testing = @import("../testing.zig");

const Parser = @import("../Parser.zig");

const Dependency = struct { step: u8, prereq: u8 };
const DepList = std.ArrayList(Dependency);
const DepTree = std.AutoHashMapUnmanaged(u8, []const u8);
const StepSet = std.AutoArrayHashMapUnmanaged(u8, void);

fn cmp(_: void, a: struct { u32, u8 }, b: struct { u32, u8 }) std.math.Order {
    const time_order = std.math.order(a[0], b[0]);
    return if (time_order == .eq) std.math.order(a[1], b[1]) else time_order;
}
const StepQueue = std.PriorityQueue(struct { u32, u8 }, void, cmp);

pub fn solve(input: solver.Input, tools: solver.Tools, p1buf: *[32]u8, p2buf: *[32]u8) solver.Error!solver.Result {
    const gpa = tools.gpa;
    var dep_list: DepList = .empty;
    defer dep_list.deinit(gpa);

    var lines = input.lines();
    while (lines.next()) |line| {
        try dep_list.append(gpa, try parseDep(line));
    }

    const steps = try getStepsSorted(gpa, dep_list.items);
    defer gpa.free(steps);
    const buf = try gpa.alloc(u8, dep_list.items.len);
    defer gpa.free(buf);
    var tree = try buildTree(gpa, buf, steps, dep_list.items);
    defer tree.deinit(gpa);

    const order = try resolutionOrder(gpa, steps, tree, p1buf);
    const time = try elapsedTime(gpa, steps, tree, 5, 60);
    const p1 = if (time) |t| std.fmt.bufPrint(p2buf, "{}", .{t}) catch unreachable else null;
    return .{ order, p1 };
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
    try testing.expectSolution(solve, .{ "CABDFE", "253" }, input);
}

fn buildTree(gpa: std.mem.Allocator, buf: []u8, steps: []const u8, deps: []Dependency) error{OutOfMemory}!DepTree {
    var tree: DepTree = .empty;
    try tree.ensureTotalCapacity(gpa, @intCast(steps.len));
    var i: usize = 0;
    for (steps) |step| {
        const start = i;
        for (deps) |dep| {
            if (dep.step == step) {
                buf[i] = dep.prereq;
                i += 1;
            }
        }
        tree.putAssumeCapacity(step, buf[start..i]);
    }
    return tree;
}

fn resolutionOrder(gpa: std.mem.Allocator, steps: []const u8, tree: DepTree, buf: []u8) error{OutOfMemory}!?[]const u8 {
    var complete: StepSet = .empty;
    defer complete.deinit(gpa);

    try complete.ensureTotalCapacity(gpa, @intCast(steps.len));

    for (0..steps.len) |i| {
        const next = for (steps) |step| {
            if (complete.contains(step)) continue;
            for (tree.get(step).?) |prereq| {
                if (!complete.contains(prereq)) break;
            } else break step;
        } else return null;
        complete.putAssumeCapacity(next, {});
        buf[i] = next;
    }
    return buf[0..steps.len];
}

fn elapsedTime(gpa: std.mem.Allocator, steps: []const u8, tree: DepTree, worker_count: u8, base_time: u8) error{OutOfMemory}!?u32 {
    var complete: StepSet = .empty;
    defer complete.deinit(gpa);
    try complete.ensureTotalCapacity(gpa, @intCast(steps.len));
    var candidates: std.AutoHashMapUnmanaged(u8, void) = .empty;
    defer candidates.deinit(gpa);
    try candidates.ensureTotalCapacity(gpa, @intCast(steps.len));
    var queue: StepQueue = .empty;
    defer queue.deinit(gpa);
    try queue.ensureTotalCapacity(gpa, worker_count);

    var available: u8 = worker_count;
    for (steps) |step| {
        if (tree.get(step).?.len == 0 and available > 0) {
            queue.push(gpa, .{ base_time + step - 64, step }) catch unreachable;
            available -= 1;
        } else {
            candidates.putAssumeCapacity(step, {});
        }
    }

    var t: u32 = 0;
    while (queue.pop()) |task| {
        available += 1;
        t = task[0];
        complete.putAssumeCapacity(task[1], {});
        for (steps) |step| {
            if (available == 0) break;
            if (!candidates.contains(step)) continue;
            const ready = for (tree.get(step).?) |prereq| {
                if (!complete.contains(prereq)) break false;
            } else true;
            if (ready) {
                _ = candidates.remove(step);
                queue.push(gpa, .{ t + base_time + step - 64, step }) catch unreachable;
                available -= 1;
            }
        }
    }
    return if (candidates.size > 0) null else t;
}

fn parseDep(str: []const u8) Parser.Error!Dependency {
    var parser: Parser = .init(str, .{});
    try parser.skip();
    const parent = try parser.takeByte();
    try parser.skipMany(5);
    const child = try parser.takeByte();
    return .{ .prereq = parent, .step = child };
}

fn getStepsSorted(gpa: std.mem.Allocator, deps: []const Dependency) error{OutOfMemory}![]const u8 {
    var set: StepSet = .empty;
    defer set.deinit(gpa);

    for (deps) |dep| {
        try set.put(gpa, dep.prereq, {});
        try set.put(gpa, dep.step, {});
    }
    const steps = try gpa.alloc(u8, set.entries.len);
    @memcpy(steps, set.keys());
    std.mem.sortUnstable(u8, steps, {}, std.sort.asc(u8));
    return steps;
}
