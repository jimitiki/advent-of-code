const std = @import("std");

const solver = @import("../solver.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    const line = try tools.input.takeDelimiter('\n') orelse return error.InvalidInput;
    const input = std.fmt.parseUnsigned(u32, line, 10) catch return error.InvalidInput;

    return .{ distance(input), null };
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

