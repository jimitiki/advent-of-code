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
    var ranges: std.ArrayList(Range) = .empty;
    while (try input.takeDelimiter('\n')) |line| {
        if (line.len == 0) break;
        var split_point: usize = 0;
        while (line[split_point] != '-') : (split_point += 1) {}
        const start = try std.fmt.parseInt(u64, line[0..split_point], 10);
        const end = try std.fmt.parseInt(u64, line[split_point + 1 ..], 10);
        try ranges.append(ini.arena, .{ .start = start, .end = end });
    }

    var answer: u32 = 0;
    while (try input.takeDelimiter('\n')) |line| {
        const id = try std.fmt.parseInt(u64, line, 10);
        for (ranges.items) |range| {
            if (id >= range.start and id <= range.end) {
                answer += 1;
                break;
            }
        }
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}
