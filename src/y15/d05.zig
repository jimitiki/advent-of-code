const std = @import("std");
const solver = @import("../solver.zig");

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    _ = tools;
    var answer1: u32 = 0;
    var answer2: u32 = 0;

    var reader = input.reader();
    while (try reader.takeDelimiter('\n')) |line| {
        if (evaluateP1(line)) answer1 += 1;
        if (evaluateP2(line)) answer2 += 1;
    }
    return .{ answer1, answer2 };
}

pub const solve = solver.intSolver(u32, solveInt);

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
