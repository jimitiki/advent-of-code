const std = @import("std");
const Io = std.Io;
const assert = std.debug.assert;

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

    var dial: u8 = 50;
    var pwd: u32 = 0;
    while (try reader.interface.takeDelimiter('\n')) |line| {
        const dir = line[0];
        if (std.fmt.parseInt(u16, line[1..line.len], 10)) |mag| {
            const change: i32 = if (dir == 'L') -@as(i32, mag) else if (dir == 'R') mag else unreachable;
            dial = @intCast(@mod(@as(i32, dial) + change, 100));
            if (test_line_p1(dial, change)) {
                pwd += 1;
            }
        } else |_| {
            try stdout.print("Error in line: {s}\n", .{line});
            try stdout.flush();
            return error.ProgramError;
        }
    }

    try stdout.print("{}\n", .{pwd});
    try stdout.flush();
}

fn test_line_p1(pos: u8, _: i32) bool {
    return pos == 0;
}
