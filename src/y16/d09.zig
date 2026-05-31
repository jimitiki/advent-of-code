const std = @import("std");

const solver = @import("../solver.zig");

fn solveInt(gpa: std.mem.Allocator, input: *std.Io.Reader) solver.Error!struct { ?usize, ?usize } {
    var length: usize = 0;
    while (true) {
        if (input.takeByte()) |char| {
            if (char == '\n' or char == ' ') {
                continue;
            } else if (char == '(') {
                length += try consumeMarker(input);
            } else {
                length += 1;
            }
        } else |_| break;
    }
    _ = gpa;
    return .{ length, null };
}

pub const solve = solver.intSolver(usize, solveInt);

fn consumeMarker(input: *std.Io.Reader) solver.Error!usize {
    const char_cnt = try consumeInt(input, 'x');
    const multiplier = try consumeInt(input, ')');
    input.discardAll(char_cnt) catch return error.InvalidInput;
    return char_cnt * multiplier;
}

fn consumeInt(input: *std.Io.Reader, delimiter: u8) solver.Error!usize {
    var buf: [8]u8 = undefined;
    var i: usize = 0;
    while (true) : (i += 1) {
        std.debug.assert(i < buf.len);
        const char = input.takeByte() catch return error.InvalidInput;
        if (char >= '0' and char <= '9') {
            buf[i] = char;
        } else if (char == delimiter) {
            return std.fmt.parseInt(u16, buf[0..i], 10) catch unreachable;
        } else {
            return error.InvalidInput;
        }
    }
}

test "solve" {
    const gpa = std.testing.allocator;
    {
        var reader = std.Io.Reader.fixed("ADVENT");
        try std.testing.expectEqual(solveInt(gpa, &reader), .{ 6, null });
    }
    {
        var reader = std.Io.Reader.fixed("A(1x5)BC");
        try std.testing.expectEqual(solveInt(gpa, &reader), .{ 7, null });
    }
    {
        var reader = std.Io.Reader.fixed("(3x3)XYZ");
        try std.testing.expectEqual(solveInt(gpa, &reader), .{ 9, null });
    }
    {
        var reader = std.Io.Reader.fixed("A(2x2)BCD(2x2)EFG");
        try std.testing.expectEqual(solveInt(gpa, &reader), .{ 11, null });
    }
    {
        var reader = std.Io.Reader.fixed("(6x1)(1x3)A");
        try std.testing.expectEqual(solveInt(gpa, &reader), .{ 6, null });
    }
    {
        var reader = std.Io.Reader.fixed("X(8x2)(3x3)ABCY");
        try std.testing.expectEqual(solveInt(gpa, &reader), .{ 18, null });
    }
}
