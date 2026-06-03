const std = @import("std");
const ArrayList = std.ArrayList;
const BitSet = std.DynamicBitSetUnmanaged;

const solver = @import("../solver.zig");

// TODO: Create a visualization

fn solveInt(tools: solver.Tools) solver.Error!struct { ?i64, ?i64 } {
    const gpa = tools.gpa;
    var width: usize = 0;
    var rows: ArrayList(BitSet) = try .initCapacity(gpa, 3);
    defer {
        for (rows.items) |*row| row.deinit(gpa);
        rows.deinit(gpa);
    }
    while (try tools.input.takeDelimiter('\n')) |line| {
        if (width == 0) {
            width = line.len;
            try rows.append(gpa, try .initEmpty(gpa, width));
        } else if (line.len != width) {
            return error.InvalidInput;
        }
        var row: BitSet = try .initEmpty(gpa, width);
        try rows.append(gpa, row);
        try parseLine(line, &row);
    }
    try rows.append(gpa, try .initEmpty(gpa, width));

    var to_remove: ArrayList(BitSet) = try .initCapacity(gpa, rows.items.len - 2);
    defer {
        for (to_remove.items) |*row| row.deinit(gpa);
        to_remove.deinit(gpa);
    }
    for (0..rows.items.len - 1) |_| {
        try to_remove.append(gpa, try .initEmpty(gpa, width));
    }

    var removed = removeOnce(&rows, &to_remove);
    const removed_first = removed;
    var sum_removed = removed;
    for (to_remove.items) |*row| row.unsetAll();
    while (removed > 0) {
        removed = removeOnce(&rows, &to_remove);
        sum_removed += removed;
    }

    return .{ removed_first, sum_removed };
}

pub const solve = solver.intSolver(i64, solveInt);

fn removeOnce(rows: *ArrayList(BitSet), to_remove: *ArrayList(BitSet)) u32 {
    findRemovable(rows.*, to_remove);
    const removed = remove(rows, to_remove.*);
    for (to_remove.items) |*row| row.unsetAll();
    return removed;
}

fn findRemovable(rows: ArrayList(BitSet), to_remove: *ArrayList(BitSet)) void {
    for (1..rows.items.len - 1) |i| {
        const top = rows.items[i - 1];
        const mid = rows.items[i];
        const bot = rows.items[i + 1];

        var removal = to_remove.items[i - 1];

        var it = mid.iterator(.{ .kind = .set });
        while (it.next()) |col| {
            var adjacent: u4 = 0;
            const left = if (col == 0) col else col - 1;
            const right = @min(mid.bit_length, col + 2);
            for (left..right) |c| {
                if (c != col and mid.isSet(c)) adjacent += 1;
                if (top.isSet(c)) adjacent += 1;
                if (bot.isSet(c)) adjacent += 1;
            }
            if (adjacent < 4) removal.set(col);
        }
    }
}

fn remove(rows: *ArrayList(BitSet), to_remove: ArrayList(BitSet)) u32 {
    var removed: u32 = 0;
    for (to_remove.items, 0..) |r, i| {
        var row = rows.items[i + 1];
        var it = r.iterator(.{ .kind = .set });
        while (it.next()) |col| {
            row.unset(col);
            removed += 1;
        }
    }
    return removed;
}

fn parseLine(line: []u8, bitset: *BitSet) !void {
    bitset.unsetAll();
    for (line, 0..) |c, i| {
        switch (c) {
            '@' => bitset.set(i),
            '.' => {},
            else => return error.InvalidInput,
        }
    }
}
