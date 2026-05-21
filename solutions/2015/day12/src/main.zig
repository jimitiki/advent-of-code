const std = @import("std");

const Boilerplate = @import("lib").Boilerplate;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;

    var answer: i64 = 0;
    var buffer: [64]u8 = undefined;
    var end: usize = 0;
    var i: usize = 0;
    while (true) : (i += 1) {
        if (input.takeByte()) |char| {
            if (end > 0) {
                if (!isDigit(char)) {
                    answer += try std.fmt.parseInt(i64, buffer[0..end], 10);
                    end = 0;
                } else {
                    buffer[end] = char;
                    end += 1;
                }
            } else {
                if (isDigit(char) or (char == '-' and if (input.peekByte()) |c| isDigit(c) else |_| false)) {
                    buffer[end] = char;
                    end += 1;
                }
            }
        } else |_| break;
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn isDigit(char: u8) bool {
    return char >= '0' and char <= '9';
}
