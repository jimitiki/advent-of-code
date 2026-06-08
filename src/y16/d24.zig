const std = @import("std");
const BitSet = std.DynamicBitSetUnmanaged;

const solver = @import("../solver.zig");

const Position = struct { x: usize, y: usize };
fn TileMap(comptime V: type) type {
    return std.array_hash_map.Auto(u8, V);
}
const PointMap = std.array_hash_map.Auto(Position, u8);

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    const gpa = tools.gpa;
    const distances = try precomputeDistances(gpa, tools.input);
    defer {
        for (distances) |d| gpa.free(d);
        gpa.free(distances);
    }
    const path_buf = try gpa.alloc(u8, distances.len);
    defer gpa.free(path_buf);
    path_buf[0] = 0;

    return .{
        shortestPath(distances, path_buf, std.math.maxInt(u16), path_buf[0..1], 0, false),
        shortestPath(distances, path_buf, std.math.maxInt(u16), path_buf[0..1], 0, true),
    };
}

pub const solve = solver.intSolver(u32, solveInt);

fn precomputeDistances(gpa: std.mem.Allocator, input: *std.Io.Reader) solver.Error![]const []const u16 {
    var layout: std.ArrayList(BitSet) = .empty;
    defer {
        for (layout.items) |*bitset| bitset.deinit(gpa);
        layout.deinit(gpa);
    }
    var points: PointMap = .empty;
    defer points.deinit(gpa);

    const width = (input.peekDelimiterExclusive('\n') catch return error.InvalidInput).len;
    var y: usize = 0;
    while (try input.takeDelimiter('\n')) |line| : (y += 1) {
        var row: BitSet = try .initEmpty(gpa, width);
        for (line, 0..) |tile, x| {
            switch (tile) {
                '.' => {},
                '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => try points.put(gpa, .{ .x = x, .y = y }, tile - 48),
                '#' => row.set(x),
                else => return error.InvalidInput,
            }
        }
        try layout.append(gpa, row);
    }
    return try cacheShortest(gpa, layout.items, points);
}

fn cacheShortest(gpa: std.mem.Allocator, layout: []const BitSet, points: PointMap) error{OutOfMemory}![]const []const u16 {
    var distances = try gpa.alloc([]u16, points.entries.len);
    for (0..distances.len) |i| {
        distances[i] = try gpa.alloc(u16, points.entries.len);
        @memset(distances[i], 0);
    }
    var queue: std.Deque(struct { u16, Position }) = .empty;
    defer queue.deinit(gpa);
    var visited: std.AutoHashMapUnmanaged(Position, void) = .empty;
    defer visited.deinit(gpa);

    for (points.keys(), points.values()) |start, tile| {
        defer visited.clearRetainingCapacity();
        defer while (queue.popFront()) |_| {};

        var point_dists = distances[tile];
        try queue.pushBack(gpa, .{ 0, start });
        try visited.put(gpa, start, {});

        while (queue.popFront()) |entry| {
            const dist, const pos = entry;
            if (points.get(pos)) |t| {
                point_dists[t] = dist;
                distances[t][tile] = dist;
            }
            if (distancesFull(point_dists, tile)) break;

            if (pos.y > 0 and !layout[pos.y - 1].isSet(pos.x)) {
                const next: Position = .{ .x = pos.x, .y = pos.y - 1 };
                if (!visited.contains(next)) {
                    try visited.put(gpa, next, {});
                    try queue.pushBack(gpa, .{ dist + 1, next });
                }
            }
            if (pos.y < layout.len - 1 and !layout[pos.y + 1].isSet(pos.x)) {
                const next: Position = .{ .x = pos.x, .y = pos.y + 1 };
                if (!visited.contains(next)) {
                    try visited.put(gpa, next, {});
                    try queue.pushBack(gpa, .{ dist + 1, next });
                }
            }
            if (pos.x > 0 and !layout[pos.y].isSet(pos.x - 1)) {
                const next: Position = .{ .x = pos.x - 1, .y = pos.y };
                if (!visited.contains(next)) {
                    try visited.put(gpa, next, {});
                    try queue.pushBack(gpa, .{ dist + 1, next });
                }
            }
            if (pos.x < layout[0].bit_length - 1 and !layout[pos.y].isSet(pos.x + 1)) {
                const next: Position = .{ .x = pos.x + 1, .y = pos.y };
                if (!visited.contains(next)) {
                    try visited.put(gpa, next, {});
                    try queue.pushBack(gpa, .{ dist + 1, next });
                }
            }
        }
    }
    return distances;
}

fn distancesFull(distances: []u16, tile: u8) bool {
    for (distances, 0..) |d, t| {
        if (t != tile and d == 0) return false;
    }
    return true;
}

fn shortestPath(
    distances: []const []const u16,
    path_buf: []u8,
    best: u16,
    path: []u8,
    dist: u16,
    go_back: bool,
) u16 {
    if (best <= dist) return std.math.maxInt(u16);
    const cur = path[path.len - 1];
    if (path.len == distances.len) {
        return if (go_back) dist + distances[cur][path[0]] else dist;
    }

    var min = best;
    const point_dists = distances[cur];
    for (point_dists, 0..) |inc_dist, i| {
        const next: u8 = @intCast(i);
        if (inPath(path, next)) continue;
        path_buf[path.len] = next;
        min = @min(min, shortestPath(
            distances,
            path_buf,
            min,
            path_buf[0 .. path.len + 1],
            dist + inc_dist,
            go_back,
        ));
    }
    return min;
}

fn inPath(path: []const u8, point: u8) bool {
    for (path) |step| {
        if (point == step) return true;
    }
    return false;
}
