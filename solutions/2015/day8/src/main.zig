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
        answer += line.len - try decodedChars(line);
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn decodedChars(string: []const u8) !usize {
    var i: usize = 1;
    var chars: usize = 0;
    if (string[0] != '"' or string[string.len - 1] != '"') {
        return error.InvalidInput;
    }
    while (i < string.len - 1) : (i += 1) {
        chars += 1;
        if (string[i] == '\\') {
            i += 1;
            switch (string[i]) {
                '"', '\\' => {},
                'x' => {
                    if (!isHex(string[i + 1]) or !isHex(string[i + 2])) {
                        return error.InvalidInput;
                    } else {
                        i += 2;
                    }
                },
                else => return error.InvalidInput,
            }
        }
    }
    return chars;
}

fn isHex(char: u8) bool {
    return char >= '0' and char <= '9' or char >= 'A' and char <= 'Z' or char >= 'a' and char <= 'z';
}
