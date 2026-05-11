const std = @import("std");

const Init = @import("lib").Init;

const Range = struct {
    start: u64,
    end: u64,

    pub fn lessThan(_: void, lhs: Range, rhs: Range) bool {
        return lhs.start < rhs.start;
    }
};

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var ini = try Init.init(init, &stdout_buffer, &read_buffer);
    defer ini.deinit();

    var stdout = &ini.stdout_writer.interface;
    var input = &ini.input_reader.interface;

    //Read ID ranges from file
    var ranges_raw: std.ArrayList(Range) = .empty;
    while (try input.takeDelimiter('\n')) |line| {
        if (line.len == 0) break;
        var split_point: usize = 0;
        while (line[split_point] != '-') : (split_point += 1) {}
        const start = try std.fmt.parseInt(u64, line[0..split_point], 10);
        const end = try std.fmt.parseInt(u64, line[split_point + 1 ..], 10);
        try ranges_raw.append(ini.arena, .{ .start = start, .end = end });
    }

    // Merge overlapping ranges
    std.sort.pdq(Range, ranges_raw.items, {}, Range.lessThan);
    var ranges: std.ArrayList(Range) = .empty;
    var range_merged: Range = .{ .start = ranges_raw.items[0].start, .end = ranges_raw.items[0].end };
    for (ranges_raw.items) |range| {
        if (range.start > range_merged.end) {
            try ranges.append(ini.arena, range_merged);
            range_merged = range;
        } else {
            range_merged.end = @max(range.end, range_merged.end);
        }
    } else {
        try ranges.append(ini.arena, range_merged);
    }

    // Handle IDs
    var answer: u32 = 0;
    while (try input.takeDelimiter('\n')) |line| {
        const id = try std.fmt.parseInt(u64, line, 10);
        for (ranges.items) |range| {
            if (id >= range.start and id <= range.end) {
                answer += 1;
            }
        }
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}
