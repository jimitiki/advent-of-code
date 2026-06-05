const std = @import("std");
const BitSet = std.DynamicBitSetUnmanaged;

const solver = @import("../solver.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?usize, ?usize } {
    const first_row = try tools.input.takeDelimiter('\n') orelse return error.InvalidInput;
    var start: BitSet = try .initEmpty(tools.gpa, first_row.len);
    defer start.deinit(tools.gpa);
    for (first_row, 0..) |char, i| {
        switch (char) {
            '.' => start.set(i),
            '^' => {},
            else => return error.InvalidInput,
        }
    }

    return .{ countSafeTiles(&start, 40), null };
}

pub const solve = solver.intSolver(usize, solveInt);

fn countSafeTiles(row: *BitSet, row_count: usize) usize {
    var count: usize = 0;
    var i: u32 = 0;
    while (i < row_count) : ({
        i += 1;
        generateRow(row);
    }) {
        count += row.count();
    }
    return count;
}

test "count safe" {
    {
        var row: BitSet = try .initEmpty(std.testing.allocator, 5);
        defer row.deinit(std.testing.allocator);
        row.masks[0] = 0b10011; // ..^^.
        try std.testing.expectEqual(6, countSafeTiles(&row, 3));
    }
    {
        var row: BitSet = try .initEmpty(std.testing.allocator, 10);
        defer row.deinit(std.testing.allocator);
        row.masks[0] = 0b0000101001; // .^^.^.^^^^
        try std.testing.expectEqual(38, countSafeTiles(&row, 10));
    }
}

fn generateRow(row: *BitSet) void {
    var left: bool = true;
    for (0..row.bit_length - 1) |i| {
        const safe = left == row.isSet(i + 1);
        left = row.isSet(i);
        row.setValue(i, safe);
    }
    row.setValue(row.bit_length - 1, left == true);
}

test "generate" {
    {
        var row: BitSet = try .initEmpty(std.testing.allocator, 5);
        defer row.deinit(std.testing.allocator);
        row.masks[0] = 0b10011; // ..^^.
        generateRow(&row);
        try std.testing.expectEqual(0b00001, row.masks[0]); // .^^^^
    }
    {
        var row: BitSet = try .initEmpty(std.testing.allocator, 10);
        defer row.deinit(std.testing.allocator);
        row.masks[0] = 0b0100100001; // .^^^^.^^.^
        generateRow(&row);
        try std.testing.expectEqual(0b1100101100, row.masks[0]); // ^^..^.^^..
    }
}
