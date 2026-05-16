const std = @import("std");

const Init = @import("lib").Init;

const Tile = struct { u64, u64 };

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var ini = try Init.init(init, &stdout_buffer, &read_buffer);
    defer ini.deinit();

    var stdout = &ini.stdout_writer.interface;
    var input = &ini.input_reader.interface;
    const validator: *const fn (Tile, Tile, []const Tile) bool = if (ini.part == .p1) validateRectP1 else validateRectP2;

    var tiles: std.ArrayList(Tile) = .empty;
    defer tiles.deinit(ini.arena);
    var answer: u64 = 0;
    while (try input.takeDelimiter('\n')) |line| {
        for (line, 0..) |c, i| {
            if (c == ',') {
                try tiles.append(ini.arena, .{
                    try std.fmt.parseUnsigned(u64, line[0..i], 10),
                    try std.fmt.parseUnsigned(u64, line[i + 1 ..], 10),
                });
            }
        }
    }
    for (tiles.items, 0..) |t1, i| {
        for (tiles.items[i + 1 ..]) |t2| {
            if (validator(t1, t2, tiles.items)) {
                answer = @max(area(t1, t2), answer);
            }
        }
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn area(t1: Tile, t2: Tile) u64 {
    return (1 + @max(t1[0], t2[0]) - @min(t1[0], t2[0])) * (1 + @max(t1[1], t2[1]) - @min(t1[1], t2[1]));
}

fn validateRectP1(_: Tile, _: Tile, _: []const Tile) bool {
    return true;
}

fn validateRectP2(t1: Tile, t2: Tile, tiles: []const Tile) bool {
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
