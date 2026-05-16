const std = @import("std");
const ArrayList = std.ArrayList;
const BitSet = std.DynamicBitSetUnmanaged;

const Init = @import("lib").Init;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var ini = try Init.init(init, &stdout_buffer, &read_buffer);
    defer ini.deinit();

    var stdout = &ini.stdout_writer.interface;
    var input = &ini.input_reader.interface;

    var answer: u32 = 0;
    var width: usize = 0;
    var rows: ArrayList(BitSet) = try .initCapacity(ini.arena, 3);
    while (try input.takeDelimiter('\n')) |line| {
        if (width == 0) {
            width = line.len;
            try rows.append(ini.arena, try .initEmpty(ini.arena, width));
        } else if (line.len != width) {
            return error.InvalidInput;
        }
        var row: BitSet = try .initEmpty(ini.arena, width);
        try rows.append(ini.arena, row);
        try parseLine(line, &row);
    }
    try rows.append(ini.arena, try .initEmpty(ini.arena, width));

    var to_remove: ArrayList(BitSet) = try .initCapacity(ini.arena, rows.items.len - 2);
    for (0..rows.items.len - 1) |_| {
        try to_remove.append(ini.arena, try .initEmpty(ini.arena, width));
    }

    while (true) {
        findRemovable(rows, &to_remove);
        const removed = remove(&rows, to_remove);
        for (to_remove.items) |*row| row.unsetAll();
        answer += removed;

        if (ini.part == .p1) break;
        if (removed == 0) break;
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
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
