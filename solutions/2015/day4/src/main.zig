const std = @import("std");

const Boilerplate = @import("boilerplate").Boilerplate;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;
    const answer = 0;
    while (try input.takeDelimiter('\n')) |line| {
        _ = line;
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}
