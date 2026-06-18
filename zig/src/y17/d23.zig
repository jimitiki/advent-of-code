const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    _ = tools;
    var parser = input.parser(.{});
    try parser.skipMany(2);
    const b = try parser.takeInt(u16);

    var h: u32 = 0;
    var i: u32 = 100000 + 100 * @as(u32, b);
    const end: u32 = i + 17000;
    while (i <= end) : (i += 17) {
        if (is_prime(i)) h += 1;
    }
    return .{ (b - 2) * (b - 2), h };
}

pub const solve = solver.intSolver(u32, solveInt);

fn is_prime(n: u32) bool {
    for (2..std.math.sqrt(n) + 1) |i| {
        if (n % i == 0) return false;
    }
    return true;
}
