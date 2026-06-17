const std = @import("std");
const solver = @import("../solver.zig");

// TODO: Use "elements": https://en.wikipedia.org/wiki/Look-and-say_sequence#Cosmological_decay

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var parser = input.parser(.{});
    const seed = try parser.take();
    var buf_cur: []u8 = tools.gpa.alloc(u8, seed.len) catch unreachable;
    defer tools.gpa.free(buf_cur);
    for (seed, 0..) |char, i| {
        buf_cur[i] = char - 48;
    }
    var sequence: []const u8 = buf_cur;
    var answer1: u32 = 0;
    for (0..50) |i| {
        const buf_next: []u8 = tools.gpa.alloc(u8, sequence.len * 2) catch unreachable;
        const next_sequence: []const u8 = lookSay(sequence, buf_next);
        tools.gpa.free(buf_cur);
        buf_cur = buf_next;
        sequence = next_sequence;
        if (i == 40) {
            answer1 = @intCast(sequence.len);
        }
    }
    const answer2: u32 = @intCast(sequence.len);
    return .{ answer1, answer2 };
}

pub const solve = solver.intSolver(u32, solveInt);

fn lookSay(sequence: []const u8, buf: []u8) []const u8 {
    var i: usize = 0;
    var j: usize = 0;
    while (i < sequence.len) : (i += 1) {
        const digit = sequence[i];
        var count: u8 = 1;
        while (i + count < sequence.len and sequence[i + count] == digit) : (count += 1) {}
        buf[j] = count;
        j += 1;
        buf[j] = digit;
        j += 1;
        i += count - 1;
    }
    return buf[0..j];
}
