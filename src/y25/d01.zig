const std = @import("std");
const Io = std.Io;
const assert = std.debug.assert;
const Boilerplate = @import("lib").Boilerplate;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;

    const algo: *const fn (u8, i32) u8 = switch (bp.part) {
        .p1 => test_line_p1,
        .p2 => test_line_p2,
    };

    var dial: u8 = 50;
    var pwd: u32 = 0;
    while (try input.takeDelimiter('\n')) |line| {
        const dir = line[0];
        if (std.fmt.parseInt(u16, line[1..line.len], 10)) |mag| {
            const change: i32 = if (dir == 'L') -@as(i32, mag) else if (dir == 'R') mag else unreachable;
            pwd += algo(dial, change);
            dial = @intCast(@mod(@as(i32, dial) + change, 100));
        } else |_| {
            try stdout.print("Error in line: {s}\n", .{line});
            try stdout.flush();
            return error.ProgramError;
        }
    }

    try stdout.print("{}\n", .{pwd});
    try stdout.flush();
}

fn test_line_p1(pos: u8, change: i32) u8 {
    return if (@mod(pos + change, 100) == 0) 1 else 0;
}

fn test_line_p2(pos: u8, change: i32) u8 {
    if (change > 0) {
        return @intCast(@divFloor(change + pos, 100));
    } else {
        const full_turns: u8 = @intCast(@divFloor(@abs(change), 100));
        const extra: u8 = @intCast(100 - @mod(change, 100));
        if (pos != 0 and extra >= pos) {
            return full_turns + 1;
        } else {
            return full_turns;
        }
    }
}
