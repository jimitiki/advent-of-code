const std = @import("std");

const solver = @import("../solver.zig");
const testing = @import("../testing.zig");

const Parser = @import("../Parser.zig");

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var parser = input.parser(.{});
    var value_list: std.ArrayList(u32) = .empty;
    defer value_list.deinit(tools.gpa);
    return try sum(tools.gpa, &parser, &value_list);
}

pub const solve = solver.intSolver(u32, solveInt);

fn sum(gpa: std.mem.Allocator, parser: *Parser, values: *std.ArrayList(u32)) solver.Error!struct { u32, u32 } {
    var metadata_sum: u32 = 0;

    const offset = values.items.len;
    const child_count = try parser.takeInt(u8);
    const metadata_count = try parser.takeInt(u8);
    for (0..child_count) |_| {
        const msum, const value = try sum(gpa, parser, values);
        metadata_sum += msum;
        try values.append(gpa, value);
    }

    var value_sum: u32 = 0;
    for (0..metadata_count) |_| {
        const metadata = try parser.takeInt(u8);
        if (metadata > 0) {
            metadata_sum += metadata;
            const index = offset + metadata - 1;
            if (index < values.items.len) {
                value_sum += values.items[index];
            }
        }
    }
    if (child_count == 0) {
        value_sum = metadata_sum;
    }
    for (0..child_count) |_| _ = values.pop().?;

    return .{ metadata_sum, value_sum };
}

test "solve" {
    const input = "2 3 0 3 10 11 12 1 1 0 1 99 2 1 1 2";
    try testing.expectIntSolution(u32, solveInt, .{ 138, 66 }, input);
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
