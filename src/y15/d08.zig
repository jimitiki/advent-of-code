const std = @import("std");
const solver = @import("../solver.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?usize, ?usize } {
    var answer1: usize = 0;
    var answer2: usize = 0;
    while (try tools.input.reader.takeDelimiter('\n')) |line| {
        answer1 += line.len - try decodedChars(line);
        answer2 += encodedChars(line) - line.len;
    }
    return .{ answer1, answer2 };
}

pub const solve = solver.intSolver(usize, solveInt);

fn encodedChars(string: []const u8) usize {
    var chars: usize = 2;
    for (string) |char| {
        chars += 1;
        if (char == '\\' or char == '"') {
            chars += 1;
        }
    }
    return chars;
}

fn decodedChars(string: []const u8) error{InvalidInput}!usize {
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
