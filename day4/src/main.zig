const std = @import("std");
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
    var width: usize = undefined;
    var rows: [3]BitSet = undefined;
    var top: usize = 0;
    var mid: usize = 1;
    var bot: usize = 2;
    if (try input.takeDelimiter('\n')) |line| {
        width = line.len;
        for (0..3) |idx| rows[idx] = try .initEmpty(ini.arena, width);
        try parseLine(line, &rows[mid]);
    }
    if (try input.takeDelimiter('\n')) |line| {
        if (line.len != width) return error.InvalidInput;
        try parseLine(line, &rows[bot]);
    }
    answer += countAccessible(rows[top], rows[mid], rows[bot]);
    while (try input.takeDelimiter('\n')) |line| {
        if (line.len != width) return error.InvalidInput;
        top = advanceRow(top);
        mid = advanceRow(mid);
        bot = advanceRow(bot);
        try parseLine(line, &rows[bot]);
        answer += countAccessible(rows[top], rows[mid], rows[bot]);
    } else {
        top = advanceRow(top);
        mid = advanceRow(mid);
        bot = advanceRow(bot);
        rows[bot].unsetAll();
        answer += countAccessible(rows[top], rows[mid], rows[bot]);
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn advanceRow(idx: usize) usize {
    return (idx + 1) % 3;
}

fn countAccessible(top: BitSet, mid: BitSet, bot: BitSet) u32 {
    var cnt: u32 = 0;
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
        if (adjacent < 4) cnt += 1;
    }
    return cnt;
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
