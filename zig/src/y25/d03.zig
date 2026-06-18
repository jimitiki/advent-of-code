const std = @import("std");

const solver = @import("../solver.zig");

const digits = "987654321";

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u64, ?u64 } {
    _ = tools;
    var answer1: u64 = 0;
    var answer2: u64 = 0;
    var reader = input.reader();
    while (try reader.takeDelimiter('\n')) |line| {
        answer1 += highestJoltage(line, 2);
        answer2 += highestJoltage(line, 12);
    }
    return .{ answer1, answer2 };
}

pub const solve = solver.intSolver(u64, solveInt);

fn highestJoltage(bank: []u8, battery_cnt: u8) u64 {
    var digit_buf: [128]u8 = undefined;
    var min_idx: usize = 0;
    for (0..battery_cnt) |jolt_idx| {
        for (digits) |digit| {
            const subbank = bank[min_idx .. bank.len - (battery_cnt - jolt_idx) + 1];
            if (findBattery(subbank, digit)) |battery_idx| {
                digit_buf[jolt_idx] = digit;
                min_idx = min_idx + battery_idx + 1;
                break;
            }
        }
    }
    return std.fmt.parseInt(u64, digit_buf[0..battery_cnt], 10) catch unreachable;
}

fn findBattery(bank: []u8, joltage: u8) ?usize {
    for (bank, 0..) |battery, i| {
        if (battery == joltage) return i;
    }
    return null;
}
