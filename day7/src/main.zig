const std = @import("std");

const Init = @import("lib").Init;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var ini = try Init.init(init, &stdout_buffer, &read_buffer);
    defer ini.deinit();

    var stdout = &ini.stdout_writer.interface;
    var input = &ini.input_reader.interface;
    const width = checkwidth: {
        const first_line = try input.peekDelimiterExclusive('\n');
        break :checkwidth first_line.len;
    };
    const paths = try ini.arena.alloc(u64, width);
    var next = try ini.arena.alloc(u64, width);
    @memset(paths, 0);
    @memset(next, 0);
    var splits: u32 = 0;
    while (try input.takeDelimiter('\n')) |line| {
        for (line, 0..) |c, i| {
            switch (c) {
                'S' => next[i] = 1,
                '.' => next[i] += paths[i],
                '^' => {
                    if (i == 0 or i == line.len - 1) return error.InvalidInput;
                    if (line[i + 1] == '^') return error.InvalidInput;
                    if (paths[i] > 0) {
                        next[i - 1] += paths[i];
                        next[i + 1] += paths[i];
                        splits += 1;
                    }
                },
                else => unreachable,
            }
        }
        @memcpy(paths, next);
        @memset(next, 0);
    }

    if (ini.part == .p1) {
        try stdout.print("{}\n", .{splits});
    } else {
        var sum: u64 = 0;
        for (paths) |path_cnt| sum += path_cnt;
        try stdout.print("{}\n", .{sum});
    }
    try stdout.flush();
}
