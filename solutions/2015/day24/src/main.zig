const std = @import("std");
const WeightList = std.ArrayList(u64);

const lib = @import("lib");
const Boilerplate = lib.Boilerplate;

const Result = struct { usize, u64 };

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;
    var weights: std.ArrayList(u64) = .empty;
    defer weights.deinit(bp.arena);
    var total_weight: u64 = 0;
    while (try input.takeDelimiter('\n')) |line| {
        const weight = try std.fmt.parseUnsigned(u64, line, 10);
        total_weight += weight;
        try weights.append(bp.arena, weight);
    }

    const target_weight = @divExact(total_weight, 3);
    std.sort.pdq(u64, weights.items, {}, weighsMore);
    var unused: WeightList = .empty;
    defer unused.deinit(bp.arena);
    _, const answer = optimizePackages(
        bp.arena,
        target_weight,
        weights.items,
        &unused,
        .{ std.math.maxInt(usize), 0 },
        0,
        0,
        1,
    ) orelse return error.Unsolvable;

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

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
            unused.append(allocator, weight) catch @panic("Out of memory");
        }
        defer {
            for (weights) |_| _ = unused.pop();
        }
        return if (checkRemainder(target_weight, unused.items, 0)) .{ count, qe } else null;
    }
    var best = best_result;
    for (weights, 0..) |weight, i| {
        defer unused.append(allocator, weight) catch @panic("Out of memory");
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
