const std = @import("std");
const lib = @import("lib");

const solver = lib.solver;
const testing = lib.testing;

pub fn solve(input: solver.Input, tools: solver.Tools, p1buf: *[32]u8, p2buf: *[32]u8) solver.Error!solver.Result {
    _ = tools;
    _ = p2buf;

    const serial_number = try input.asInt(u16);
    var grid: [300][300]i16 = undefined;
    setPowerLevels(serial_number, &grid);

    _, const coord = findMaxSquare(grid);
    return .{ std.fmt.bufPrint(p1buf, "{},{}", .{ coord[0], coord[1] }) catch unreachable, null };
}

// test "solve" {
//     try testing.expectSolution(solve, .{ "33,45", null }, "18");
//     try testing.expectSolution(solve, .{ "21,61", null }, "42");
// }

fn setPowerLevels(serial_number: u16, grid: *[300][300]i16) void {
    for (grid, 1..) |*row, y| {
        for (row, 1..) |*cell, x| {
            cell.* = computePowerLevel(serial_number, x, y);
        }
    }
}

fn computePowerLevel(serial_number: u16, x: usize, y: usize) i16 {
    const rack_id = x + 10;
    const m = (rack_id * y + serial_number) * rack_id;
    const u = m / 100;
    const v: i16 = @intCast(u % 10);
    return v - 5;
}

test "power level" {
    try std.testing.expectEqual(4, computePowerLevel(8, 3, 5));
    try std.testing.expectEqual(-5, computePowerLevel(57, 122, 79));
    try std.testing.expectEqual(0, computePowerLevel(39, 217, 196));
    try std.testing.expectEqual(4, computePowerLevel(71, 101, 153));
}

fn findMaxSquare(grid: [300][300]i16) struct { i16, struct { usize, usize } } {
    var max_power: i16 = std.math.minInt(u16);
    var coord: struct { usize, usize } = undefined;
    for (0..298) |i| {
        for (0..298) |j| {
            var power: i16 = 0;
            for (i..i + 3) |k| {
                for (j..j + 3) |l| {
                    power += grid[k][l];
                }
            }
            if (power > max_power) {
                max_power = power;
                coord = .{ j + 1, i + 1 };
            }
        }
    }
    return .{ max_power, coord };
}

test "find max" {
    var grid: [300][300]i16 = undefined;

    setPowerLevels(18, &grid);
    try std.testing.expectEqual(.{ 29, .{ 33, 45 } }, findMaxSquare(grid));

    setPowerLevels(42, &grid);
    try std.testing.expectEqual(.{ 30, .{ 21, 61 } }, findMaxSquare(grid));
}
