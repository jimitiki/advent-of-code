const std = @import("std");

const solver = @import("../solver.zig");
const hash = @import("../hash.zig");

const Candidate = struct { index: usize, char: u8 };
const Queue = std.Deque(Candidate);

fn solveInt(tools: solver.Tools) solver.Error!struct { ?usize, ?usize } {
    const salt = try tools.input.takeDelimiter('\n') orelse return error.InvalidInput;
    return .{
        try computeIndex(tools.gpa, salt, 64, 0),
        try computeIndex(tools.gpa, salt, 64, 2016),
    };
}

pub const solve = solver.intSolver(usize, solveInt);

fn computeIndex(gpa: std.mem.Allocator, salt: []const u8, key_cnt: usize, hash_stretches: usize) error{OutOfMemory}!?usize {
    var candidates: Queue = .empty;
    defer candidates.deinit(gpa);
    var quintuples = [_]usize{0} ** 16;
    var buf: [32]u8 = undefined;
    var hex: [32]u8 = undefined;

    var count: usize = 0;
    var index: usize = 0;
    while (count < key_cnt) : (index += 1) {
        stretchHash(salt, index, &buf, &hex, hash_stretches);

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
    try std.testing.expectEqual(22728, try computeIndex(std.testing.allocator, "abc", 64, 0));
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

fn stretchHash(salt: []const u8, index: usize, buf: []u8, hex: *[32]u8, n: usize) void {
    hash.hashIndex(salt, index, buf, hex) catch @panic("Buffer is too small");
    for (0..n) |_| {
        hash.hashStr(hex, hex);
    }
}

test "hash stretching" {
    var hex: [32]u8 = undefined;
    var buf: [4]u8 = undefined;
    stretchHash("abc", 0, &buf, &hex, 0);
    try std.testing.expectEqualSlices(u8, "577571be4de9dcce85a041ba0410f29f", &hex);
    stretchHash("abc", 0, &buf, &hex, 1);
    try std.testing.expectEqualSlices(u8, "eec80a0c92dc8a0777c619d9bb51e910", &hex);
    stretchHash("abc", 0, &buf, &hex, 2);
    try std.testing.expectEqualSlices(u8, "16062ce768787384c81fe17a7a60c7e3", &hex);
    stretchHash("abc", 0, &buf, &hex, 2016);
    try std.testing.expectEqualSlices(u8, "a107ff634856bb300138cac6568c0f24", &hex);
}
