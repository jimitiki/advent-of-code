const std = @import("std");

const solver = @import("../solver.zig");
const hashIndex = @import("../hash.zig").hashIndex;

const Candidate = struct { index: usize, char: u8 };
const Queue = std.Deque(Candidate);

fn solveInt(tools: solver.Tools) solver.Error!struct { ?usize, ?usize } {
    const salt = try tools.input.takeDelimiter('\n') orelse return error.InvalidInput;
    return .{ try computeIndex(tools.gpa, salt, 64), null };
}

pub const solve = solver.intSolver(usize, solveInt);

fn computeIndex(gpa: std.mem.Allocator, salt: []const u8, key_cnt: usize) error{OutOfMemory}!?usize {
    var candidates: Queue = .empty;
    defer candidates.deinit(gpa);
    var quintuples = [_]usize{0} ** 16;
    var buf: [32]u8 = undefined;
    var hex: [32]u8 = undefined;

    var count: usize = 0;
    var index: usize = 0;
    while (count < key_cnt) : (index += 1) {
        hashIndex(salt, index, &buf, &hex) catch @panic("Buffer is not big enough");

        if (checkThree(&hex)) |char| {
            try candidates.pushBack(gpa, .{
                .index = index,
                .char = std.fmt.charToDigit(char, 16) catch unreachable,
            });
            for (hex[0 .. hex.len - 4], 0..) |c, i| {
                if (std.mem.allEqual(u8, hex[i .. i + 5], c)) {
                    quintuples[std.fmt.charToDigit(c, 16) catch unreachable] = index;
                }
            }
        }
        if (candidates.front()) |candidate| {
            if (index - candidate.index == 1000) {
                if (candidate.index < quintuples[candidate.char]) {
                    count += 1;
                    if (count == key_cnt) {
                        return candidate.index;
                    }
                }
                _ = candidates.popFront();
            }
        }
    }
    return null;
}

test "compute index" {
    try std.testing.expectEqual(22728, try computeIndex(std.testing.allocator, "abc", 64));
}

fn checkThree(hex: *[32]u8) ?u8 {
    for (hex[0 .. hex.len - 2], 0..) |char, i| {
        if (hex[i] != char) continue;
        if (hex[i + 1] != char) continue;
        if (hex[i + 2] != char) continue;
        return char;
    }
    return null;
}
