const std = @import("std");

const solver = @import("../solver.zig");
const testing = @import("../testing.zig");

const Counter = @import("../counter.zig").Counter;

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    const ids = try input.sliceLines(tools.gpa);
    defer tools.gpa.free(ids);
    return .{ checksum(ids), null };
}

pub const solve = solver.intSolver(u16, solveInt);

fn checksum(ids: []const []const u8) u16 {
    var count_two: u16 = 0;
    var count_three: u16 = 0;
    var counts: [26]u8 = undefined;
    for (ids) |id| {
        @memset(&counts, 0);
        for (id) |char| {
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
    return count_two * count_three;
}

test "checksum" {
    const ids: [7][]const u8 = .{
        "abcdef",
        "bababc",
        "abbcde",
        "abcccd",
        "aabcdd",
        "abcdee",
        "ababab",
    };
    try std.testing.expectEqual(12, checksum(&ids));
}
