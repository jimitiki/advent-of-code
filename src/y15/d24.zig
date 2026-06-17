const std = @import("std");
const WeightList = std.ArrayList(u64);

const solver = @import("../solver.zig");

const Result = struct { usize, u64 };

// TODO: Ensure that packages can be grouped correctly when the number of groups is more than 3

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u64, ?u64 } {
    var weights: std.ArrayList(u64) = .empty;
    defer weights.deinit(tools.gpa);
    var total_weight: u64 = 0;
    while (try tools.input.reader.takeDelimiter('\n')) |line| {
        const weight = std.fmt.parseUnsigned(u64, line, 10) catch return error.InvalidInput;
        total_weight += weight;
        weights.append(tools.gpa, weight) catch unreachable;
    }

    std.sort.pdq(u64, weights.items, {}, weighsMore);
    var unused: WeightList = .empty;
    defer unused.deinit(tools.gpa);
    _, const answer1 = optimizePackages(
        tools.gpa,
        @divExact(total_weight, 3),
        weights.items,
        &unused,
        .{ std.math.maxInt(usize), 0 },
        0,
        0,
        1,
    ) orelse .{ void, null };
    _, const answer2 = optimizePackages(
        tools.gpa,
        @divExact(total_weight, 4),
        weights.items,
        &unused,
        .{ std.math.maxInt(usize), 0 },
        0,
        0,
        1,
    ) orelse .{ void, null };
    return .{ answer1, answer2 };
}

pub const solve = solver.intSolver(u64, solveInt);

fn optimizePackages(
    allocator: std.mem.Allocator,
    target_weight: u64,
    weights: []const u64,
    unused: *WeightList,
    best_result: Result,
    count: usize,
    total_weight: u64,
    qe: u64,
) ?Result {
    if (total_weight > target_weight or count > best_result[0]) {
        return null;
    } else if (total_weight == target_weight) {
        if (count > best_result[0] or count == best_result[0] and qe >= best_result[1]) {
            return null;
        }
        for (weights) |weight| {
            unused.append(allocator, weight) catch unreachable;
        }
        defer {
            for (weights) |_| _ = unused.pop();
        }
        return if (checkRemainder(target_weight, unused.items, 0)) .{ count, qe } else null;
    }
    var best = best_result;
    for (weights, 0..) |weight, i| {
        defer unused.append(allocator, weight) catch unreachable;
        best = optimizePackages(
            allocator,
            target_weight,
            weights[i + 1 ..],
            unused,
            best,
            count + 1,
            total_weight + weight,
            qe * weight,
        ) orelse continue;
    }
    for (weights) |_| _ = unused.pop(); // Every weight in weignts was added to unused
    return best;
}

fn cmpResults(r1: ?Result, r2: ?Result) ?Result {
    const res1 = r1 orelse return r2;
    const res2 = r2 orelse return r1;
    if (res1[0] < res2[0]) {
        return res1;
    } else if (res1[0] == res2[0] and res1[1] < res2[1]) {
        return res1;
    } else {
        return res2;
    }
}

fn checkRemainder(
    target_weight: u64,
    weights: []const u64,
    total_weight: u64,
) bool {
    if (total_weight > target_weight) {
        return false;
    } else if (total_weight == target_weight) {
        return true;
    }
    for (weights, 0..) |weight, i| {
        if (checkRemainder(target_weight, weights[i + 1 ..], total_weight + weight)) {
            return true;
        }
    }
    return false;
}

fn weighsMore(_: void, lhs: u64, rhs: u64) bool {
    return lhs > rhs;
}
