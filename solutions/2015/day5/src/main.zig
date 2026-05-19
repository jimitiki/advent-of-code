const std = @import("std");

const Boilerplate = @import("boilerplate").Boilerplate;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;
    var answer: usize = 0;
    while (try input.takeDelimiter('\n')) |line| {
        var vowels: usize = 0;
        var double: bool = false;
        if (isVowel(line[0])) {
            vowels += 1;
        }
        const contains_bad = for (line[0 .. line.len - 1], line[1..]) |a, b| {
            if (isVowel(b)) {
                vowels += 1;
            }
            if (a == b) {
                double = true;
            }
            if (isForbiddenPair(a, b)) {
                break true;
            }
        } else false;
        if (vowels >= 3 and double and !contains_bad) {
            answer += 1;
        }
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn isVowel(char: u8) bool {
    return switch (char) {
        'a', 'e', 'i', 'o', 'u' => true,
        else => false,
    };
}

fn isForbiddenPair(a: u8, b: u8) bool {
    return switch (a) {
        'a' => b == 'b',
        'c' => b == 'd',
        'p' => b == 'q',
        'x' => b == 'y',
        else => false,
    };
}
