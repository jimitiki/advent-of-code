const std = @import("std");
const lib = @import("lib");

const solver = lib.solver;
const testing = lib.testing;

const Counter = lib.Counter(usize);
const Parser = lib.Parser;

const Pos = struct {
    x: u32,
    y: u32,
};

// Currently, this is just a brute force solution. A proper flood fill or sweep line algorithm
// would probably be faster.

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    const gpa = tools.gpa;
    var coord_list: std.ArrayList(Pos) = .empty;
    defer coord_list.deinit(gpa);

    var lines = input.lines();
    while (lines.next()) |line| {
        var parser: Parser = .init(line, .{});
        try coord_list.append(gpa, .{ .x = try parser.takeInt(u32), .y = try parser.takeInt(u32) });
    }

    var xmin: u32 = std.math.maxInt(u32);
    var xmax: u32 = 0;
    var ymin: u32 = std.math.maxInt(u32);
    var ymax: u32 = 0;
    for (coord_list.items) |pos| {
        xmin = @min(xmin, pos.x);
        xmax = @max(xmax, pos.x);
        ymin = @min(ymin, pos.y);
        ymax = @max(ymax, pos.y);
    }

    var infinite: std.AutoHashMapUnmanaged(usize, void) = .empty;
    defer infinite.deinit(gpa);

    for (ymin..ymax + 1) |y| {
        if (closestCoord(coord_list.items, .{ .x = xmin, .y = @intCast(y) })) |idx| {
            try infinite.put(gpa, idx, {});
        }
        if (closestCoord(coord_list.items, .{ .x = xmax, .y = @intCast(y) })) |idx| {
            try infinite.put(gpa, idx, {});
        }
    }
    for (xmin + 1..xmax) |x| {
        if (closestCoord(coord_list.items, .{ .x = @intCast(x), .y = ymin })) |idx| {
            try infinite.put(gpa, idx, {});
        }
        if (closestCoord(coord_list.items, .{ .x = @intCast(x), .y = ymax })) |idx| {
            try infinite.put(gpa, idx, {});
        }
    }

    var ctr: Counter = .empty;
    defer ctr.deinit(gpa);

    for (ymin + 1..ymax) |y| {
        for (xmin + 1..xmax) |x| {
            const idx = closestCoord(coord_list.items, .{ .x = @intCast(x), .y = @intCast(y) }) orelse continue;
            if (!infinite.contains(idx)) {
                _ = try ctr.add(gpa, idx);
            }
        }
    }

    var count: u32 = 0;
    for (ymin..ymax + 1) |y| {
        for (xmin..xmax + 1) |x| {
            const dist_sum = sumDistance(coord_list.items, .{ .x = @intCast(x), .y = @intCast(y) });
            if (dist_sum <= 10000) {
                count += 1;
            }
        }
    }

    return .{ @intCast(ctr.max()[1]), count };
}

pub const solve = solver.intSolver(u32, solveInt);

fn closestCoord(coords: []const Pos, pos: Pos) ?usize {
    var min_dist: u32 = std.math.maxInt(u32);
    var index: usize = undefined;
    var count: usize = 0;
    for (coords, 0..) |c, i| {
        const dist = distance(pos, c);
        if (dist < min_dist) {
            min_dist = dist;
            index = i;
            count = 1;
        } else if (dist == min_dist) {
            count += 1;
        }
    }
    return if (count > 1) null else index;
}

fn sumDistance(coords: []const Pos, pos: Pos) u32 {
    var sum: u32 = 0;
    for (coords) |c| {
        sum += distance(pos, c);
    }
    return sum;
}

fn distance(a: Pos, b: Pos) u32 {
    return subAbs(u32, a.x, b.x) + subAbs(u32, a.y, b.y);
}

fn subAbs(comptime T: type, a: T, b: T) T {
    return if (a > b) a - b else b - a;
}

fn indexToChar(i: usize) u8 {
    const offset: u8 = if (i < 10) 48 else if (i < 36) 55 else 61;
    return @intCast(i + offset);
}
