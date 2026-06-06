const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

// TODO: Use `modpow`?

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u64, ?u64 } {
    const line = (try tools.input.takeDelimiter('\n')) orelse return error.InvalidInput;
    var parser: Parser = .init(line, .{});
    try parser.skipMany(15);
    const col = try parser.takeInt(u64);
    try parser.skip();
    const row = try parser.takeInt(u64);

    var code: u64 = 20151125;
    compute: for (2..row + col) |i| {
        for (1..i + 1) |c| {
            const r = i + 1 - c;
            code = (code * 252533) % 33554393;
            if (c == col and r == row) {
                break :compute;
            }
        }
    }
    return .{ code, null };
}

pub const solve = solver.intSolver(u64, solveInt);
