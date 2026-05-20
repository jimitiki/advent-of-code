const std = @import("std");

const Boilerplate = @import("lib").Boilerplate;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;
    var answer: u64 = 0;
    while (try input.takeDelimiter('\n')) |line| {
        var i: usize = 1;
        var mem_chars: usize = 0;
        if (line[0] != '"' or line[line.len - 1] != '"') {
            return error.InvalidInput;
        }
        while (i < line.len - 1) : (i += 1) {
            mem_chars += 1;
            if (line[i] == '\\') {
                i += 1;
                switch (line[i]) {
                    '"', '\\' => {},
                    'x' => {
                        if (!isHex(line[i + 1]) or !isHex(line[i + 2])) {
                            return error.InvalidInput;
                        } else {
                            i += 2;
                        }
                    },
                    else => return error.InvalidInput,
                }
            }
        }
        answer += line.len - mem_chars;
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn isHex(char: u8) bool {
    return char >= '0' and char <= '9' or char >= 'A' and char <= 'Z' or char >= 'a' and char <= 'z';
}
