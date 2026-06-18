const std = @import("std");
const solver = @import("../solver.zig");

pub fn solve(input: solver.Input, tools: solver.Tools, p1buf: *[32]u8, p2buf: *[32]u8) solver.Error!solver.Result {
    var parser = input.parser(.{});
    const old = try parser.take();
    const pw: []u8 = tools.gpa.alloc(u8, old.len) catch unreachable;
    @memcpy(pw, old);
    defer tools.gpa.free(pw);
    const answer1 = nextValidPassword(pw, p1buf) orelse return .{ null, null };
    return .{ answer1, nextValidPassword(pw, p2buf) };
}

fn nextValidPassword(pw: []u8, buf: []u8) ?[]const u8 {
    increment(pw) catch return null;
    while (!isValid(pw)) : (increment(pw) catch return null) {}
    @memcpy(buf[0..pw.len], pw);
    return buf[0..pw.len];
}

fn increment(pw: []u8) error{Unsolvable}!void {
    for (1..pw.len + 1) |i| {
        const pos = pw.len - i;
        pw[pos] = (pw[pos] - 96) % 26 + 97;
        if (pw[pos] != 'a') {
            break;
        }
    } else return error.Unsolvable;
}

fn isValid(pw: []u8) bool {
    const straight = for (pw[0 .. pw.len - 2], pw[1 .. pw.len - 1], pw[2..pw.len]) |c1, c2, c3| {
        if (c1 + 1 == c2 and c2 + 1 == c3) {
            break true;
        }
    } else false;
    const legal = for (pw) |char| {
        if (char == 'i' or char == 'l' or char == 'o') {
            break false;
        }
    } else true;
    const two_pairs = pair: for (0..pw.len - 3) |i| {
        if (pw[i] != pw[i + 1]) {
            continue;
        }
        for (i + 2..pw.len - 1) |j| {
            if (pw[j] == pw[j + 1] and pw[j] != pw[i]) {
                break :pair true;
            }
        }
    } else false;
    return straight and legal and two_pairs;
}
