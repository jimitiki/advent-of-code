const std = @import("std");

const solver = @import("../solver.zig");

const Rotation = enum { column, row };

const Operation = union(enum) {
    rect: struct { usize, usize },
    rotate: struct { Rotation, usize, usize },
};

// TODO: Make an animation

pub fn solve(gpa: std.mem.Allocator, input: *std.Io.Reader, buf1: []u8, buf2: []u8) solver.Error!solver.Result {
    _ = buf2;
    var screen = [_]u50{0} ** 6;
    while (try input.takeDelimiter('\n')) |instruction| {
        try execute(u50, &screen, gpa, instruction);
    }

    var pixels_on: u32 = 0;
    for (screen) |row| {
        for (0..50) |shift_offset| {
            if (row & std.math.shl(u50, 1, 50 - shift_offset) != 0) {
                pixels_on += 1;
                std.debug.print("█", .{});
            } else {
                std.debug.print(" ", .{});
            }
        }
        std.debug.print("\n", .{});
    }

    return .{
        std.fmt.bufPrint(buf1, "{}", .{pixels_on}) catch unreachable,
        "see console output",
    };
}

fn execute(comptime T: type, screen: []T, gpa: std.mem.Allocator, instruction: []const u8) solver.Error!void {
    const operation = try parseOperation(instruction);
    switch (operation) {
        .rect => |dim| try rect(T, screen, dim[0], dim[1]),
        .rotate => |rot| {
            switch (rot[0]) {
                .column => try rotateColumn(T, screen, gpa, rot[1], rot[2]),
                .row => try rotateRow(T, screen, rot[1], rot[2]),
            }
        },
    }
}

test "execute" {
    const gpa = std.testing.allocator;
    var screen = [_]u7{0} ** 3;
    try execute(u7, &screen, gpa, "rect 3x2");
    try std.testing.expectEqual([_]u7{
        0b1110000,
        0b1110000,
        0b0000000,
    }, screen);
    try execute(u7, &screen, gpa, "rotate column x=1 by 1");
    try std.testing.expectEqual([_]u7{
        0b1010000,
        0b1110000,
        0b0100000,
    }, screen);
    try execute(u7, &screen, gpa, "rotate row y=0 by 4");
    try std.testing.expectEqual([_]u7{
        0b0000101,
        0b1110000,
        0b0100000,
    }, screen);
    try execute(u7, &screen, gpa, "rotate column x=1 by 1");
    try std.testing.expectEqual([_]u7{
        0b0100101,
        0b1010000,
        0b0100000,
    }, screen);
}

fn parseOperation(str: []const u8) error{InvalidInput}!Operation {
    if (str.len < 7) {
        return error.InvalidInput;
    } else if (std.mem.eql(u8, str[0..5], "rect ")) {
        return .{ .rect = try parseRect(str[5..]) };
    } else if (std.mem.eql(u8, str[0..7], "rotate ")) {
        return .{ .rotate = try parseRotate(str[7..]) };
    } else {
        return error.InvalidInput;
    }
}

fn parseRect(str: []const u8) error{InvalidInput}!struct { usize, usize } {
    for (str, 0..) |char, i| {
        if (char != 'x') {
            continue;
        }
        return .{
            std.fmt.parseUnsigned(usize, str[0..i], 10) catch return error.InvalidInput,
            std.fmt.parseUnsigned(usize, str[i + 1 ..], 10) catch return error.InvalidInput,
        };
    }
    return error.InvalidInput;
}

fn parseRotate(str: []const u8) error{InvalidInput}!struct { Rotation, usize, usize } {
    const rotation: Rotation, const params = gettype: {
        if (str.len < 9) {
            return error.InvalidInput;
        } else if (std.mem.eql(u8, str[0..6], "row y=")) {
            break :gettype .{ .row, str[6..] };
        } else if (std.mem.eql(u8, str[0..9], "column x=")) {
            break :gettype .{ .column, str[9..] };
        } else {
            return error.InvalidInput;
        }
    };
    const entry, const idx = for (params, 0..) |char, i| {
        if (char == ' ') {
            break .{
                std.fmt.parseUnsigned(usize, params[0..i], 10) catch return error.InvalidInput,
                i + 4,
            };
        }
    } else return error.InvalidInput;
    return .{
        rotation,
        entry,
        std.fmt.parseUnsigned(usize, params[idx..], 10) catch return error.InvalidInput,
    };
}

test "parse" {
    try std.testing.expectError(error.InvalidInput, parseOperation(""));
    try std.testing.expectError(error.InvalidInput, parseOperation("rec 73x49"));
    try std.testing.expectError(error.InvalidInput, parseOperation("rotste row y=1 by 1"));
    try std.testing.expectError(error.InvalidInput, parseOperation("rotate row x=1 by 1"));
    try std.testing.expectError(error.InvalidInput, parseOperation("rotate column y=1 by 1"));
    try std.testing.expectError(error.InvalidInput, parseOperation("rotate column x=1 by "));
    {
        const expected: Operation = .{ .rect = .{ 3, 2 } };
        try std.testing.expectEqual(expected, try parseOperation("rect 3x2"));
    }
    {
        const expected: Operation = .{ .rect = .{ 20, 358 } };
        try std.testing.expectEqual(expected, try parseOperation("rect 20x358"));
    }
    {
        const expected: Operation = .{ .rotate = .{ .column, 0, 1 } };
        try std.testing.expectEqual(expected, try parseOperation("rotate column x=0 by 1"));
    }
    {
        const expected: Operation = .{ .rotate = .{ .row, 86, 989 } };
        try std.testing.expectEqual(expected, try parseOperation("rotate row y=86 by 989"));
    }
}

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
    return std.math.shl(T, ~@as(T, 0), bit_count - width);
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

fn rotateColumn(
    comptime T: type,
    screen: []T,
    gpa: std.mem.Allocator,
    col: usize,
    amount: usize,
) error{ InvalidInput, OutOfMemory }!void {
    const bit_count: T = @typeInfo(T).int.bits;
    if (col >= bit_count) {
        return error.InvalidInput;
    }

    var rotated: std.DynamicBitSetUnmanaged = try .initEmpty(gpa, screen.len);
    defer rotated.deinit(gpa);

    const bit_mask = std.math.shl(T, 1, bit_count - col - 1);
    for (screen, 0..) |row, i| {
        if (row & bit_mask != 0) {
            rotated.set((i + amount) % screen.len);
        }
    }
    for (screen, 0..) |*row, i| {
        if (rotated.isSet(i)) {
            row.* |= bit_mask;
        } else {
            row.* &= ~bit_mask;
        }
    }
}

test "rotate column" {
    const gpa = std.testing.allocator;
    {
        var screen = [_]u7{
            0b1110000,
            0b1110000,
            0b0000000,
        };
        const expected = [_]u7{
            0b1010000,
            0b1110000,
            0b0100000,
        };
        try rotateColumn(u7, &screen, gpa, 1, 1);
        try std.testing.expectEqual(expected, screen);
    }
    {
        var screen = [_]u7{
            0b1110000,
            0b1110000,
            0b0000000,
        };
        const expected = [_]u7{
            0b1010000,
            0b1110000,
            0b0100000,
        };
        try rotateColumn(u7, &screen, gpa, 1, 13);
        try std.testing.expectEqual(expected, screen);
    }
    {
        var screen = [_]u7{
            0b0000101,
            0b1110000,
            0b0100000,
        };
        const expected = [_]u7{
            0b0100101,
            0b1010000,
            0b0100000,
        };
        try rotateColumn(u7, &screen, gpa, 1, 1);
        try std.testing.expectEqual(expected, screen);
    }
    {
        var screen = [_]u7{0} ** 3;
        try std.testing.expectError(error.InvalidInput, rotateColumn(u7, &screen, gpa, 10, 0));
    }
}
