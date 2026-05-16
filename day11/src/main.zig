const std = @import("std");

const Init = @import("lib").Init;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var ini = try Init.init(init, &stdout_buffer, &read_buffer);
    defer ini.deinit();

    var stdout = &ini.stdout_writer.interface;
    var input = &ini.input_reader.interface;
    _ = try input.takeDelimiter('\n');

    const answer = 0;

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}
