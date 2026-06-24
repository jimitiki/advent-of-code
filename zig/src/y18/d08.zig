const std = @import("std");

const solver = @import("../solver.zig");
const testing = @import("../testing.zig");

const Parser = @import("../Parser.zig");

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    _ = tools;

    var parser = input.parser(.{});
    return .{ try sumMetadata(&parser), null };
}

pub const solve = solver.intSolver(u32, solveInt);

fn sumMetadata(parser: *Parser) solver.Error!u32 {
    var sum: u32 = 0;

    const child_count = try parser.takeInt(u8);
    const metadata_count = try parser.takeInt(u8);
    for (0..child_count) |_| sum += try sumMetadata(parser);
    for (0..metadata_count) |_| sum += try parser.takeInt(u8);

    return sum;
}

test "sum" {
    const input = "2 3 0 3 10 11 12 1 1 0 1 99 2 1 1 2";
    var parser: Parser = .init(input, .{});
    try std.testing.expectEqual(138, try sumMetadata(&parser));
}

fn next(parser: *Parser) Parser.Error!?u8 {
    if (parser.takeInt(u8)) |i| {
        return i;
    } else |err| {
        switch (err) {
            error.EndOfBuffer => return null,
            else => |e| return e,
        }
    }
}
