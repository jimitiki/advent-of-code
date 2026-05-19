const std = @import("std");

const Boilerplate = @import("lib").Boilerplate;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [1]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;
    var floor: i32 = 0;
    var pos: i32 = 1;
    while (true) : (pos += 1) {
        if (input.takeByte()) |c| {
            switch (c) {
                '(' => floor += 1,
                ')' => floor -= 1,
                else => break,
            }
            if (bp.part == .p2 and floor < 0) break;
        } else |_| break;
    }

    const answer = switch (bp.part) {
        .p1 => floor,
        .p2 => pos,
    };
    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}
