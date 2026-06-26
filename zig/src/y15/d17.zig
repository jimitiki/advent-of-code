const std = @import("std");
const lib = @import("lib");

const solver = lib.solver;

// TODO: Potentially represent containers with a bitset

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var containers: std.ArrayList(u32) = .empty;
    defer containers.deinit(tools.gpa);

    var reader = input.reader();
    while (try reader.takeDelimiter('\n')) |line| {
        const capacity = std.fmt.parseUnsigned(u32, line, 10) catch return error.InvalidInput;
        containers.append(tools.gpa, capacity) catch unreachable;
    }

    const limit = minUsed(containers.items, 0, 0);
    return .{
        countCombinations(containers.items, 0, 0, 0),
        countCombinations(containers.items, 0, 0, limit),
    };
}

pub const solve = solver.intSolver(u32, solveInt);

fn countCombinations(containers: []u32, capacity: u32, used: u32, limit: u32) u32 {
    if (limit > 0 and used > limit) {
        return 0;
    } else if (capacity == 150) {
        return 1;
    } else if (capacity > 150) {
        return 0;
    } else if (containers.len == 0) {
        return 0;
    }

    var count: u32 = 0;
    for (containers, 0..) |container, i| {
        count += countCombinations(containers[i + 1 ..], capacity + container, used + 1, limit);
    }
    return count;
}

fn minUsed(containers: []u32, capacity: u32, used: u32) u32 {
    if (capacity == 150) {
        return used;
    } else if (capacity > 150) {
        return std.math.maxInt(u32);
    } else if (containers.len == 0) {
        return std.math.maxInt(u32);
    }

    var min_used: u32 = std.math.maxInt(u32);
    for (containers, 0..) |container, i| {
        min_used = @min(min_used, minUsed(containers[i + 1 ..], capacity + container, used + 1));
    }
    return min_used;
}
