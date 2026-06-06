const std = @import("std");

const solver = @import("../solver.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    while (try tools.input.takeDelimiter('\n')) |line| {
        _ = line;
    }
    return .{ null, null };
}

pub const solve = solver.intSolver(u32, solveInt);

const Dir = enum { l, r };

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
