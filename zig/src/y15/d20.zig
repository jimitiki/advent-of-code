const std = @import("std");

const solver = @import("../solver.zig");

// TODO: Implement a faster sum of divisors algorithm

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    _ = tools;
    const target = try input.asInt(u32);
    var answer1: u32 = 1;
    while (sumPresents(answer1) < target) : (answer1 += 1) {}
    var answer2: u32 = 1;
    while (sumPresentsModified(answer2) < target) : (answer2 += 1) {}
    return .{ answer1, answer2 };
}

pub const solve = solver.intSolver(u32, solveInt);

fn sumPresents(house: u32) u32 {
    if (house == 1) {
        return 10;
    }

    var sum: u32 = 1 + house;
    const sqrt = @sqrt(@as(f64, @floatFromInt(house)));
    const cutoff: u32 = @round(sqrt);
    var divisor: u32 = 2;
    while (divisor <= cutoff) : (divisor += 1) {
        if (house % divisor != 0) {
            continue;
        }
        const quotient = house / divisor;
        sum += divisor;
        if (divisor != quotient) sum += quotient;
    }
    return sum * 10;
}

fn sumPresentsModified(house: u32) u32 {
    if (house == 1) {
        return 10;
    }

    var sum: u32 = house;
    if (house <= 50) {
        sum += 1;
    }
    const sqrt = @sqrt(@as(f64, @floatFromInt(house)));
    const cutoff: u32 = @min(50, @as(u32, @round(sqrt)));
    var divisor: u32 = 2;
    while (divisor <= cutoff) : (divisor += 1) {
        if (house % divisor != 0) {
            continue;
        }
        const quotient = house / divisor;
        if (quotient <= 50) {
            sum += divisor;
        }
        if (divisor != quotient) sum += quotient;
    }
    return sum * 11;
}
