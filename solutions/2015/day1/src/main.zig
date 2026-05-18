const std = @import("std");

const Boilerplate = @import("boilerplate").Boilerplate;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [1]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;
    var answer: i32 = 0;
    while (true) {
        if (input.takeByte()) |c| {
            switch (c) {
                '(' => answer += 1,
                ')' => answer -= 1,
                else => break,
            }
        } else |_| break;
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}
