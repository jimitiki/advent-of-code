const std = @import("std");

const solver = @import("../solver.zig");
const testing = @import("../testing.zig");

const Counter = @import("../counter.zig").Counter;

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    _ = tools;
    var count_two: u16 = 0;
    var count_three: u16 = 0;
    var counts: [26]u8 = undefined;
    var reader = input.reader();
    while (try reader.takeDelimiter('\n')) |line| {
        @memset(&counts, 0);
        for (line) |char| {
            counts[char - 97] += 1;
        }
        for (counts) |c| {
            if (c == 2) {
                count_two += 1;
                break;
            }
        }
        for (counts) |c| {
            if (c == 3) {
                count_three += 1;
                break;
            }
        }
    }
    return .{ count_two * count_three, null };
}

pub const solve = solver.intSolver(u16, solveInt);

test "solve" {
    const input =
        \\abcdef
        \\bababc
        \\abbcde
        \\abcccd
        \\aabcdd
        \\abcdee
        \\ababab
    ;
    try testing.expectIntSolution(u16, solveInt, .{ 12, null }, input);
}
