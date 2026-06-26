const std = @import("std");
const lib = @import("lib");

const solver = lib.solver;
const testing = lib.testing;

const Counter = lib.Counter;

pub fn solve(input: solver.Input, tools: solver.Tools, p1buf: *[32]u8, p2buf: *[32]u8) solver.Error!solver.Result {
    const ids = try input.sliceLines(tools.gpa);
    defer tools.gpa.free(ids);
    return .{
        std.fmt.bufPrint(p1buf, "{}", .{checksum(ids)}) catch unreachable,
        matchingLetters(p2buf, ids),
    };
}

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

fn matchingLetters(buf: []u8, ids: []const []const u8) ?[]const u8 {
    for (ids, 0..) |a, i| {
        for (ids[i..]) |b| {
            if (diffIndex(a, b)) |index| {
                for (a, 0..) |char, j| {
                    if (j == index) {
                        continue;
                    } else if (j > index) {
                        buf[j - 1] = char;
                    } else {
                        buf[j] = char;
                    }
                }
                return buf[0 .. a.len - 1];
            }
        }
    }
    return null;
}

test "part 2" {
    const ids: [7][]const u8 = .{
        "abcde",
        "fghij",
        "klmno",
        "pqrst",
        "fguij",
        "axcye",
        "wvxyz",
    };
    var buf: [32]u8 = undefined;
    try std.testing.expectEqualSlices(u8, "fgij", matchingLetters(&buf, &ids).?);
}

fn diffIndex(a: []const u8, b: []const u8) ?usize {
    if (a.len != b.len) return null;
    var found = false;
    var index: usize = undefined;
    for (a, b, 0..) |ca, cb, i| {
        if (ca != cb) {
            if (found) {
                return null;
            }
            found = true;
            index = i;
        }
    }
    if (!found) {
        return null;
    }
    return index;
}
