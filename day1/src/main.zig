const std = @import("std");
const Io = std.Io;
const assert = std.debug.assert;

var dial: i32 = 50;

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();

    const io = init.io;
    var stdout_buffer: [256]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    const input_file = try std.Io.Dir.cwd().openFile(io, "data/test.txt", .{});
    defer input_file.close(io);

    var read_buffer: [256]u8 = undefined;
    var reader = input_file.reader(io, &read_buffer);
    var inputs = try std.ArrayList([]const u8).initCapacity(arena, 128);
    defer inputs.deinit(arena);
    while (try reader.interface.takeDelimiter('\n')) |line| {
        try inputs.append(arena, line);
    }

    var zeroes: u32 = 0;
    for (inputs.items) |input| {
        const dir = input[0];
        const mag = try std.fmt.parseInt(u16, input[1..input.len], 10);
        if (dir == 'L') {
            dial = @mod(dial - mag, 100);
        } else if (dir == 'R') {
            dial = @mod(dial + mag, 100);
        } else {
            unreachable;
        }
        if (dial == 0) {
            zeroes += 1;
        }
    }

    try stdout.print("{}\n", .{zeroes});
    try stdout.flush();
}
