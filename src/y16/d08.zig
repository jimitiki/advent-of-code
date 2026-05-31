const std = @import("std");

const solver = @import("../solver.zig");

fn solveInt(gpa: std.mem.Allocator, input: *std.Io.Reader) solver.Error!struct { ?u32, ?u32 } {
    _ = gpa;
    _ = input;
    return .{ null, null };
}

pub const solve = solver.intSolver(u32, solveInt);

fn rect(comptime T: type, screen: []T, width: usize, height: usize) error{InvalidInput}!void {
    if (height > screen.len) {
        return error.InvalidInput;
    } else if (height == 0 or width == 0) {
        return;
    }
    const mask = try rectBitMask(T, @intCast(width));
    for (screen[0..height]) |*row| {
        row.* |= mask;
    }
}

fn rectBitMask(comptime T: type, width: T) error{InvalidInput}!T {
    if (width == 0) {
        return 0;
    }
    const bit_count: T = @typeInfo(T).int.bits;
    if (width > bit_count) {
        return error.InvalidInput;
    }
    const zero_mask = std.math.shl(T, 1, bit_count - width) -| 1;
    return (@as(T, 1) <<| bit_count) ^ zero_mask;
}

test "rect" {
    {
        var screen = [_]u7{0b0000000} ** 3;
        const expected = [_]u7{ 0b1110000, 0b1110000, 0b0000000 };
        try rect(u7, &screen, 3, 2);
        try std.testing.expectEqual(expected, screen);
    }
    {
        var screen = [_]u7{0b0000000} ** 3;
        const expected = [_]u7{ 0b1111111, 0b1111111, 0b1111111 };
        try rect(u7, &screen, 7, 3);
        try std.testing.expectEqual(expected, screen);
    }
    {
        var screen = [_]u7{0b0000000} ** 3;
        const expected = [_]u7{
            0b1111110,
            0b0000000,
            0b0000000,
        };
        try rect(u7, &screen, 6, 1);
        try std.testing.expectEqual(expected, screen);
    }
    {
        var screen = [_]u7{
            0b0110011,
            0b1100000,
            0b0001111,
        };
        const expected = [_]u7{
            0b1111111,
            0b1111110,
            0b1111111,
        };
        try rect(u7, &screen, 6, 3);
        try std.testing.expectEqual(expected, screen);
    }
    {
        var screen = [_]u7{
            0b1100011,
            0b0011100,
            0b1110011,
        };
        const expected = [_]u7{
            0b1100011,
            0b0011100,
            0b1110011,
        };
        try rect(u7, &screen, 0, 3);
        try std.testing.expectEqual(expected, screen);
    }
    {
        var screen = [_]u7{
            0b1100011,
            0b0011100,
            0b1110011,
        };
        const expected = [_]u7{
            0b1100011,
            0b0011100,
            0b1110011,
        };
        try rect(u7, &screen, 7, 0);
        try std.testing.expectEqual(expected, screen);
    }
    {
        var screen = [_]u50{0b10000000000000000000000000000000000000000000000001} ** 5;
        try rect(u50, &screen, 30, 4);
        try std.testing.expectEqual(
            [_]u50{0b11111111111111111111111111111100000000000000000001} ** 4 ++ [_]u50{0b10000000000000000000000000000000000000000000000001},
            screen,
        );
    }
}

test "rect bit mask" {
    try std.testing.expectEqual(0b0000000, rectBitMask(u7, 0));
    try std.testing.expectEqual(0b1000000, rectBitMask(u7, 1));
    try std.testing.expectEqual(0b1110000, rectBitMask(u7, 3));
    try std.testing.expectEqual(0b1111110, rectBitMask(u7, 6));
    try std.testing.expectEqual(0b1111111, rectBitMask(u7, 7));
    try std.testing.expectEqual(0b11111110000000000000000, rectBitMask(u23, 7));

    try std.testing.expectError(error.InvalidInput, rectBitMask(u7, 8));
}

fn rotateRow(comptime T: type, screen: []T, row: usize, amount: usize) error{InvalidInput}!void {
    if (row >= screen.len) {
        return error.InvalidInput;
    }
    screen[row] = std.math.rotr(T, screen[row], amount);
}

test "rotate row" {
    {
        var screen = [_]u7{
            0b1010000,
            0b1110000,
            0b0100000,
        };
        const expected = [_]u7{
            0b0000101,
            0b1110000,
            0b0100000,
        };
        try rotateRow(u7, &screen, 0, 4);
        try std.testing.expectEqual(expected, screen);
    }
    {
        var screen = [_]u7{
            0b1100011,
            0b0011100,
            0b1110011,
        };
        const expected = [_]u7{
            0b1100011,
            0b1000011,
            0b1110011,
        };
        try rotateRow(u7, &screen, 1, 3);
        try std.testing.expectEqual(expected, screen);
    }
    {
        var screen = [_]u7{
            0b1100011,
            0b0011100,
            0b1110011,
        };
        const expected = [_]u7{
            0b1100011,
            0b1000011,
            0b1110011,
        };
        try rotateRow(u7, &screen, 1, 10);
        try std.testing.expectEqual(expected, screen);
    }
    {
        var screen = [_]u7{
            0b1100011,
            0b0011100,
            0b1110011,
        };
        const expected = [_]u7{
            0b1100011,
            0b0011100,
            0b1110011,
        };
        try rotateRow(u7, &screen, 1, 0);
        try std.testing.expectEqual(expected, screen);
    }
    {
        var screen = [_]u7{0} ** 3;
        try std.testing.expectError(error.InvalidInput, rotateRow(u7, &screen, 3, 0));
    }
}
