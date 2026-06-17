const std = @import("std");

const solver = @import("../solver.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    const digits = tools.input.reader.takeDelimiterExclusive('\n') catch return error.InvalidInput;
    return .{ sumAdjacent(digits), sumOpposite(digits) };
}

fn sumAdjacent(digits: []const u8) u16 {
    var sum: u16 = 0;
    for (digits, 0..) |digit, i| {
        if (digit == digits[(i + 1) % digits.len]) sum += digit - 48;
    }
    return sum;
}

test "adjacent" {
    try std.testing.expectEqual(3, sumAdjacent("1122"));
    try std.testing.expectEqual(4, sumAdjacent("1111"));
    try std.testing.expectEqual(0, sumAdjacent("1234"));
    try std.testing.expectEqual(9, sumAdjacent("91212129"));
}

fn sumOpposite(digits: []const u8) u16 {
    const offset = @divExact(digits.len, 2);
    var sum: u16 = 0;
    for (digits[0..offset], 0..) |digit, i| {
        if (digit == digits[(i + offset) % digits.len]) sum += (digit - 48) * 2;
    }
    return sum;
}

test "opposite" {
    try std.testing.expectEqual(6, sumOpposite("1212"));
    try std.testing.expectEqual(0, sumOpposite("1221"));
    try std.testing.expectEqual(4, sumOpposite("123425"));
    try std.testing.expectEqual(12, sumOpposite("123123"));
    try std.testing.expectEqual(4, sumOpposite("12131415"));
}

pub const solve = solver.intSolver(u16, solveInt);
