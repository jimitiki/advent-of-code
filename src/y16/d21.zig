const std = @import("std");

const solver = @import("../solver.zig");
const WordIterator = @import("../parse.zig").WordIterator;

const Operation = enum { move, reverse, rotate, swap };
const Dir = enum { l, r };

pub fn solve(tools: solver.Tools) solver.Error!solver.Result {
    var buf: [8]u8 = undefined;
    @memcpy(&buf, "abcdefgh");
    const pw = buf[0..];
    while (try tools.input.takeDelimiter('\n')) |line| {
        var it: WordIterator = .init(line);
        const op = std.meta.stringToEnum(Operation, it.next() orelse return error.InvalidInput) orelse return error.InvalidInput;
        switch (op) {
            .move => {
                _ = it.next();
                const a, const b = try parsePositions(&it);
                move(pw, a, b);
            },
            .reverse => {
                _ = it.next();
                const a, const b = try parsePositions(&it);
                reverse(pw, a, b);
            },
            .rotate => {
                const mode = it.next() orelse return error.InvalidInput;
                if (std.mem.eql(u8, mode, "based")) {
                    for (0..4) |_| _ = it.next();
                    const char = it.next() orelse return error.InvalidInput;
                    if (char.len != 1) return error.InvalidInput;
                    rotateAtLetter(pw, char[0]);
                } else {
                    const n = try parseInt(it.next() orelse return error.InvalidInput);
                    if (std.mem.eql(u8, mode, "left")) {
                        rotate(pw, n, .l);
                    } else if (std.mem.eql(u8, mode, "right")) {
                        rotate(pw, n, .r);
                    } else {
                        return error.InvalidInput;
                    }
                }
            },
            .swap => {
                const mode = it.next() orelse return error.InvalidInput;
                if (std.mem.eql(u8, mode, "position")) {
                    const a, const b = try parsePositions(&it);
                    swap(pw, a, b);
                } else if (std.mem.eql(u8, mode, "letter")) {
                    const a = it.next() orelse return error.InvalidInput;
                    _ = it.next();
                    _ = it.next();
                    const b = it.next() orelse return error.InvalidInput;
                    if (a.len != 1 or b.len != 1) {
                        return error.InvalidInput;
                    } else {
                        swapLetters(pw, a[0], b[0]);
                    }
                }
            },
        }
    }
    @memcpy(tools.p2buf[0..pw.len], pw);
    return .{ tools.p2buf[0..pw.len], null };
}

fn parsePositions(it: *WordIterator) error{InvalidInput}!struct { usize, usize } {
    const a = try parseInt(it.next() orelse return error.InvalidInput);
    _ = it.next();
    const maybe = it.next() orelse return error.InvalidInput;
    const b = if (it.next()) |pos| try parseInt(pos) else try parseInt(maybe);
    return .{ a, b };
}

fn parseInt(str: []const u8) error{InvalidInput}!usize {
    return std.fmt.parseUnsigned(usize, str, 10) catch return error.InvalidInput;
}

fn swap(pw: []u8, a: usize, b: usize) void {
    const temp = pw[a];
    pw[a] = pw[b];
    pw[b] = temp;
}

fn swapLetters(pw: []u8, a: u8, b: u8) void {
    var i: usize = 0;
    var j: usize = 0;
    while (pw[i] != a or pw[j] != b) {
        if (pw[i] != a) i += 1;
        if (pw[j] != b) j += 1;
    }
    swap(pw, i, j);
}

fn rotate(pw: []u8, n: usize, dir: Dir) void {
    const amount = if (dir == .r) pw.len - (n % pw.len) else (n % pw.len);
    if (amount == 0) return;
    reverse(pw, 0, amount - 1);
    reverse(pw, amount, pw.len - 1);
    reverse(pw, 0, pw.len - 1);
}

fn rotateAtLetter(pw: []u8, char: u8) void {
    var i: usize = 0;
    while (pw[i] != char) : (i += 1) {}
    var rot = 1 + i;
    if (i >= 4) rot += 1;
    rotate(pw, rot, .r);
}

fn reverse(pw: []u8, start: usize, end: usize) void {
    var i = start;
    var j = end;
    while (i < j) : ({
        i += 1;
        j -= 1;
    }) swap(pw, i, j);
}

fn move(pw: []u8, source: usize, dest: usize) void {
    if (dest == source) return;
    var i = source;
    if (dest > source) {
        while (i < dest) : (i += 1) swap(pw, i, i + 1);
    } else {
        while (i > dest) : (i -= 1) swap(pw, i, i - 1);
    }
}

test "operations" {
    var pw: [5]u8 = undefined;
    @memcpy(&pw, "abcde");
    swap(&pw, 4, 0);
    try std.testing.expectEqualSlices(u8, "ebcda", &pw);
    swapLetters(&pw, 'd', 'b');
    try std.testing.expectEqualSlices(u8, "edcba", &pw);
    reverse(&pw, 0, 4);
    try std.testing.expectEqualSlices(u8, "abcde", &pw);
    rotate(&pw, 1, .l);
    try std.testing.expectEqualSlices(u8, "bcdea", &pw);
    move(&pw, 1, 4);
    try std.testing.expectEqualSlices(u8, "bdeac", &pw);
    move(&pw, 3, 0);
    try std.testing.expectEqualSlices(u8, "abdec", &pw);
    rotateAtLetter(&pw, 'b');
    try std.testing.expectEqualSlices(u8, "ecabd", &pw);
    rotateAtLetter(&pw, 'd');
    try std.testing.expectEqualSlices(u8, "decab", &pw);
}
