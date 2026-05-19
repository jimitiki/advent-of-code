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
        if (switch (bp.part) {
            .p1 => evaluateP1(line),
            .p2 => evaluateP2(line),
        }) {
            answer += 1;
        }
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn evaluateP1(string: []const u8) bool {
    if (string.len < 3) {
        return false;
    }
    var vowels: usize = 0;
    var double: bool = false;
    if (isVowel(string[0])) {
        vowels += 1;
    }
    for (string[0 .. string.len - 1], string[1..]) |a, b| {
        if (isVowel(b)) {
            vowels += 1;
        }
        if (a == b) {
            double = true;
        }
        if (isForbiddenPair(a, b)) {
            return false;
        }
    }
    return vowels >= 3 and double;
}

fn evaluateP2(string: []const u8) bool {
    if (string.len < 4) {
        return false;
    }
    const split_repeat = for (string[0 .. string.len - 2], string[2..]) |a, b| {
        if (a == b) {
            break true;
        }
    } else false;
    const double_pair = dbl: for (0..string.len - 3) |i| {
        for (i + 2..string.len - 1) |j| {
            if (string[i] == string[j] and string[i + 1] == string[j + 1]) {
                break :dbl true;
            }
        }
    } else false;
    return split_repeat and double_pair;
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
