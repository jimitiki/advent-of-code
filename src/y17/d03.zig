const std = @import("std");

const solver = @import("../solver.zig");

const Position = struct { i16, i16 };
const Grid = std.AutoHashMapUnmanaged(Position, u32);
const Dir = enum {
    down,
    left,
    right,
    up,

    fn next(self: Dir) Dir {
        return switch (self) {
            .down => .right,
            .left => .down,
            .right => .up,
            .up => .left,
        };
    }
};

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    const line = try tools.input.takeDelimiter('\n') orelse return error.InvalidInput;
    const input = std.fmt.parseUnsigned(u32, line, 10) catch return error.InvalidInput;

    return .{ distance(input), try findLarger(tools.gpa, input) };
}

pub const solve = solver.intSolver(u32, solveInt);

fn distance(index: u32) u32 {
    if (index == 1) return 0;

    // Compute the lowest and highest number in the particular "ring" of the spiral in which the
    // index is located
    var ring: u32 = 1;
    var ring_start: u32 = 2;
    var ring_end: u32 = 9;
    while (index > ring_end) {
        ring += 1;
        ring_start = ring_end + 1;
        ring_end = std.math.pow(u32, ring * 2 + 1, 2);
    }

    // Compute the distance to the "center" of the edge of the ring
    const edge_size = ring * 2; // Number of squares in an edge. The bottom right corner "belongs" to the bottom edge, etc.
    const center = ring - 1; // Distance from the first index of the edge to the same row or column as the "1" square
    const offset = (index - ring_start) % edge_size; // Distance from the first index of the edge to the index
    const edge_dist = if (offset > center) offset - center else center - offset;

    // Finally, compute the distance to the center of the spiral and return the sum of the two
    // distances
    return edge_dist + ring;
}

test "distance" {
    try std.testing.expectEqual(0, distance(1));
    try std.testing.expectEqual(3, distance(12));
    try std.testing.expectEqual(2, distance(23));
    try std.testing.expectEqual(31, distance(1024));
}

fn findLarger(gpa: std.mem.Allocator, target: u32) error{OutOfMemory}!u32 {
    var grid: Grid = .empty;
    defer grid.deinit(gpa);

    var position: Position = .{ 0, 0 };
    var ring: u32 = 0;
    var edge_size: u32 = 0;
    var edge_end: u32 = 2;
    var dir: Dir = .right;
    var index: u32 = 1;
    while (try computeValue(gpa, &grid, position) <= target) {
        index += 1;
        switch (dir) {
            .down => position[1] += 1,
            .left => position[0] -= 1,
            .right => position[0] += 1,
            .up => position[1] -= 1,
        }
        if (index == edge_end) {
            dir = dir.next();
            if (dir == .right) {
                edge_end += edge_size + 1;
            } else if (dir == .up) {
                ring += 1;
                edge_size = ring * 2;
                edge_end = edge_end + edge_size - 1;
            } else {
                edge_end += edge_size;
            }
        }
    }

    return grid.get(position).?;
}

fn computeValue(gpa: std.mem.Allocator, grid: *Grid, position: Position) error{OutOfMemory}!u32 {
    var sum: u32 = 0;
    for (0..3) |i| {
        const x = position[0] + @as(i8, @intCast(i)) - 1;
        for (0..3) |j| {
            const y = position[1] + @as(i8, @intCast(j)) - 1;
            if (x == position[0] and y == position[1]) continue;
            sum += grid.get(.{ x, y }) orelse 0;
        }
    }
    sum = @max(1, sum);
    try grid.put(gpa, position, sum);
    return sum;
}

test "find larger" {
    const gpa = std.testing.allocator;
    try std.testing.expectEqual(23, try findLarger(gpa, 22));
    try std.testing.expectEqual(330, try findLarger(gpa, 329));
    try std.testing.expectEqual(351, try findLarger(gpa, 330));
}
