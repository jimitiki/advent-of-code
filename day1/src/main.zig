const std = @import("std");
const Io = std.Io;
const assert = std.debug.assert;

var dial: i32 = 50;

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    assert(args.len > 1);

    const io = init.io;
    var stdout_buffer: [256]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    const file_path = try std.fmt.allocPrint(arena, "data/{s}.txt", .{args[1]});
    const input_file = try std.Io.Dir.cwd().openFile(io, file_path, .{});
    defer input_file.close(io);

    var read_buffer: [256]u8 = undefined;
    var reader = input_file.reader(io, &read_buffer);
    var inputs = try std.ArrayList([]const u8).initCapacity(arena, 128);
    defer inputs.deinit(arena);

    var zeroes: u32 = 0;
    while (try reader.interface.takeDelimiter('\n')) |line| {
        const dir = line[0];
        if (std.fmt.parseInt(u16, line[1..line.len], 10)) |mag| {
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
        } else |_| {
            try stdout.print("Error in line: {s}\n", .{line});
            try stdout.flush();
            return error.ProgramError;
        }
    }

    try stdout.print("{}\n", .{zeroes});
    try stdout.flush();
}
