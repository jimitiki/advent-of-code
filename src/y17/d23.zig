const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    const line = try tools.input.takeDelimiter('\n') orelse return error.InvalidInput;
    var parser: Parser = .init(line, .{});
    try parser.skipMany(2);
    const b = try parser.takeInt(u16);
    return .{ (b - 2) * (b - 2), null };
}

pub const solve = solver.intSolver(u32, solveInt);
