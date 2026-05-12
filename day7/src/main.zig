const std = @import("std");

const Init = @import("lib").Init;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var ini = try Init.init(init, &stdout_buffer, &read_buffer);
    defer ini.deinit();

    var stdout = &ini.stdout_writer.interface;
    var input = &ini.input_reader.interface;
    const width = compw: {
        const first_line = try input.peekDelimiterExclusive('\n');
        break :compw first_line.len;
    };
    var beams: std.DynamicBitSetUnmanaged = try .initEmpty(ini.arena, width);
    var next: std.DynamicBitSetUnmanaged = try .initEmpty(ini.arena, width);
    var answer: u32 = 0;
    while (try input.takeDelimiter('\n')) |line| {
        for (line, 0..) |c, i| {
            switch (c) {
                'S' => next.set(i),
                '.' => if (beams.isSet(i)) next.set(i),
                '^' => {
                    if (i == 0 or i == line.len - 1) return error.InvalidInput;
                    if (line[i + 1] == '^') return error.InvalidInput;
                    next.unset(i);
                    if (beams.isSet(i)) {
                        next.set(i - 1);
                        next.set(i + 1);
                        answer += 1;
                    }
                },
                else => unreachable,
            }
        }
        beams.unsetAll();
        beams.setUnion(next);
        next.unsetAll();
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}
