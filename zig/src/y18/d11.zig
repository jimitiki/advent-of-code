const std = @import("std");
const lib = @import("lib");

const solver = lib.solver;
const testing = lib.testing;

const Coord = struct { usize, usize };

// TODO: Speed up part 2: Use a heuristic to limit square size, memoize certain sums to skip/simplify certain calculations.

pub fn solve(input: solver.Input, tools: solver.Tools, p1buf: *[32]u8, p2buf: *[32]u8) solver.Error!solver.Result {
    _ = tools;

    const serial_number = try input.asInt(u16);
    var grid: [300][300]i8 = undefined;
    setPowerLevels(serial_number, &grid);

    _, const coord1 = findMaxSquare3x3(grid);
    _, const coord2, const size = findMaxSquare(grid);
    return .{
        std.fmt.bufPrint(p1buf, "{},{}", .{ coord1[0], coord1[1] }) catch unreachable,
        std.fmt.bufPrint(p2buf, "{},{},{}", .{ coord2[0], coord2[1], size }) catch unreachable,
    };
}

// Too slow
// test "solve" {
//     try testing.expectSolution(solve, .{ "33,45", "90,269,16" }, "18");
//     try testing.expectSolution(solve, .{ "21,61", "232,251,12" }, "42");
// }

fn setPowerLevels(serial_number: u16, grid: *[300][300]i8) void {
    for (grid, 1..) |*row, y| {
        for (row, 1..) |*cell, x| {
            cell.* = computePowerLevel(serial_number, x, y);
        }
    }
}

fn computePowerLevel(serial_number: u16, x: usize, y: usize) i8 {
    const rack_id = x + 10;
    const m = (rack_id * y + serial_number) * rack_id;
    const u = m / 100;
    const v: i8 = @intCast(u % 10);
    return v - 5;
}

test "power level" {
    try std.testing.expectEqual(4, computePowerLevel(8, 3, 5));
    try std.testing.expectEqual(-5, computePowerLevel(57, 122, 79));
    try std.testing.expectEqual(0, computePowerLevel(39, 217, 196));
    try std.testing.expectEqual(4, computePowerLevel(71, 101, 153));
}

fn findMaxSquare3x3(grid: [300][300]i8) struct { i32, Coord } {
    var max_power: i32 = std.math.minInt(u16);
    var coord: Coord = undefined;
    for (0..298) |i| {
        for (0..298) |j| {
            var power: i32 = 0;
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

fn findMaxSquare(grid: [300][300]i8) struct { i32, Coord, u16 } {
    var max_power: i32 = std.math.minInt(u16);
    var coord: Coord = undefined;
    var s: usize = undefined;
    for (0..300) |i| {
        for (0..300) |j| {
            var power: i32 = 0;
            const max_size = @min(300 - i, 300 - j);
            for (1..max_size + 1) |size| {
                for (i..i + size) |k| {
                    power += grid[k][j + size - 1];
                }
                for (j..j + size - 1) |l| {
                    power += grid[i + size - 1][l];
                }
                if (power > max_power) {
                    max_power = power;
                    coord = .{ j + 1, i + 1 };
                    s = size;
                }
            }
        }
    }
    return .{ max_power, coord, @intCast(s) };
}
