const std = @import("std");

const solver = @import("../solver.zig");

const Tile = struct { u64, u64 };

// TODO: Fix rect intersects. Currently, it will approve a rectangle whose points lie on the edge
// of a concavity in the tile polygon such that the inside of the rectangle covers the outside.
// Is there a way to do it with just testing that the center of the rectangle is within the
// polygon?

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u64, ?u64 } {
    var tiles: std.ArrayList(Tile) = .empty;
    defer tiles.deinit(tools.gpa);
    while (try tools.input.reader.takeDelimiter('\n')) |line| {
        for (line, 0..) |c, i| {
            if (c == ',') {
                try tiles.append(tools.gpa, .{
                    std.fmt.parseUnsigned(u64, line[0..i], 10) catch return error.InvalidInput,
                    std.fmt.parseUnsigned(u64, line[i + 1 ..], 10) catch return error.InvalidInput,
                });
            }
        }
    }

    var max_rect: u64 = 0;
    var max_green_rect: u64 = 0;
    for (tiles.items, 0..) |t1, i| {
        for (tiles.items[i + 1 ..]) |t2| {
            max_rect = @max(max_rect, area(t1, t2));
            if (validateRect(t1, t2, tiles.items)) {
                max_green_rect = @max(area(t1, t2), max_green_rect);
            }
        }
    }

    return .{ max_rect, max_green_rect };
}

pub const solve = solver.intSolver(u64, solveInt);

fn area(t1: Tile, t2: Tile) u64 {
    return (1 + @max(t1[0], t2[0]) - @min(t1[0], t2[0])) * (1 + @max(t1[1], t2[1]) - @min(t1[1], t2[1]));
}

fn validateRect(t1: Tile, t2: Tile, tiles: []const Tile) bool {
    const r1 = .{ @min(t1[0], t2[0]), @min(t1[1], t2[1]) };
    const r2 = .{ @max(t1[0], t2[0]), @max(t1[1], t2[1]) };
    for (tiles, 0..) |p1, i| {
        const p2 = tiles[(i + 1) % tiles.len];
        if (rectIntersects(r1, r2, p1, p2)) return false;
    }
    return true;
}

test "rect intersection" {
    try std.testing.expect(rectIntersects(.{ 2, 1 }, .{ 11, 5 }, .{ 7, 3 }, .{ 2, 3 }));
    try std.testing.expect(rectIntersects(.{ 2, 1 }, .{ 11, 3 }, .{ 7, 1 }, .{ 7, 3 }));
}

/// Determines if a line segmented determined by start and end points p1 and p2 intersects with the
/// rectangle determined by the points r1 and r2.
///
/// r1 must be the bottom left corner, and r2 must be the top right corner, assuming standard
/// cartesian coordinates. The line segment must be horizontal or vertical.
fn rectIntersects(r1: Tile, r2: Tile, p1: Tile, p2: Tile) bool {
    if (@min(p1[0], p2[0]) >= r2[0]) return false;
    if (@max(p1[0], p2[0]) <= r1[0]) return false;
    if (@min(p1[1], p2[1]) >= r2[1]) return false;
    if (@max(p1[1], p2[1]) <= r1[1]) return false;
    return true;
}

test "in polygon" {
    const tiles: [8]Tile = .{
        .{ 7, 1 },
        .{ 11, 1 },
        .{ 11, 7 },
        .{ 9, 7 },
        .{ 9, 5 },
        .{ 2, 5 },
        .{ 2, 3 },
        .{ 7, 3 },
    };
    try std.testing.expect(inPolygon(2, 3, &tiles));
    try std.testing.expect(inPolygon(2, 5, &tiles));
    try std.testing.expect(inPolygon(9, 5, &tiles));
    try std.testing.expect(inPolygon(9, 3, &tiles));
}

fn inPolygon(x: usize, y: usize, tiles: []const Tile) bool {
    var in_polygon = false;
    for (tiles, 0..) |start, i| {
        const end = tiles[(i + 1) % tiles.len];
        if (start[0] == end[0]) {
            // Test vertical line. If the point is on the vertical line, it is considered to be
            // inside the polygon. Otherwise, it is not counted, because the ray will be cast
            // upwards.
            if (x == start[0] and y >= @min(start[1], end[1]) and y <= @max(start[1], end[1])) {
                return true;
            }
        } else if (y == start[1] and x >= @min(start[0], end[0]) and x <= @max(start[0], end[0])) {
            // Handle horizontal line, where the point is on the line.
            return true;
        } else if (y < start[1] and x >= @min(start[0], end[0]) and x < @max(start[0], end[0])) {
            // Handle horizontal line, where the point is below any point on the line except the
            // right-most point.
            in_polygon = !in_polygon;
        }
    }
    return in_polygon;
}
