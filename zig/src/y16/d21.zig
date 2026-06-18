const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

const Action = enum { move, reverse, rotate, swap };
const Dir = enum {
    left,
    right,

    fn rev(self: Dir) Dir {
        return if (self == .left) .right else .left;
    }
};
const SwapMode = enum { letter, position };
const Operation = union(Action) {
    move: struct { usize, usize },
    reverse: struct { usize, usize },
    rotate: union(enum) {
        letter: u8,
        amount: struct { Dir, usize },
    },
    swap: union(SwapMode) {
        letter: struct { u8, u8 },
        position: struct { usize, usize },
    },
};

pub fn solve(input: solver.Input, tools: solver.Tools, p1buf: *[32]u8, p2buf: *[32]u8) solver.Error!solver.Result {
    const pw = p1buf[0..8];
    @memcpy(pw, "abcdefgh");

    const scrambled = p2buf[0..8];
    @memcpy(scrambled, "fbgdceah");

    var operations: std.ArrayList(Operation) = .empty;
    defer operations.deinit(tools.gpa);
    var reader = input.reader();
    while (try reader.takeDelimiter('\n')) |line| {
        try operations.append(tools.gpa, try parseOperation(line));
    }
    runOperations(pw, operations.items);
    revOperations(scrambled, operations.items);
    return .{ pw, scrambled };
}

fn parseOperation(str: []const u8) Parser.Error!Operation {
    var parser: Parser = .init(str, .{});
    const op = try parser.takeEnum(Action);
    switch (op) {
        .move => {
            try parser.skip();
            const a = try parser.takeInt(usize);
            try parser.skipMany(2);
            const b = try parser.takeInt(usize);
            return .{ .move = .{ a, b } };
        },
        .reverse => {
            try parser.skip();
            const a = try parser.takeInt(usize);
            try parser.skip();
            const b = try parser.takeInt(usize);
            return .{ .reverse = .{ a, b } };
        },
        .rotate => {
            const mode = try parser.take();
            if (std.mem.eql(u8, mode, "based")) {
                try parser.skipMany(4);
                return .{ .rotate = .{ .letter = try parser.takeByte() } };
            } else {
                const dir = std.meta.stringToEnum(Dir, mode) orelse return error.InvalidToken;
                return .{ .rotate = .{ .amount = .{ dir, try parser.takeInt(usize) } } };
            }
        },
        .swap => {
            const mode = try parser.takeEnum(SwapMode);
            switch (mode) {
                .position => {
                    const a = try parser.takeInt(usize);
                    try parser.skipMany(2);
                    const b = try parser.takeInt(usize);
                    return .{ .swap = .{ .position = .{ a, b } } };
                },
                .letter => {
                    const a = try parser.takeByte();
                    try parser.skipMany(2);
                    const b = try parser.takeByte();
                    return .{ .swap = .{ .letter = .{ a, b } } };
                },
            }
        },
    }
}

fn runOperations(pw: []u8, operations: []const Operation) void {
    for (operations) |op| {
        switch (op) {
            .move => |positions| move(pw, positions[0], positions[1]),
            .reverse => |positions| reverse(pw, positions[0], positions[1]),
            .rotate => |mode| {
                switch (mode) {
                    .amount => |p| rotate(pw, p[1], p[0]),
                    .letter => |char| rotrAtLetter(pw, char),
                }
            },
            .swap => |mode| {
                switch (mode) {
                    .letter => |chars| swapLetters(pw, chars[0], chars[1]),
                    .position => |positions| swap(pw, positions[0], positions[1]),
                }
            },
        }
    }
}

fn revOperations(pw: *[8]u8, operations: []const Operation) void {
    var i = operations.len;
    while (i > 0) : (i -= 1) {
        const op = operations[i - 1];
        switch (op) {
            .move => |positions| move(pw, positions[1], positions[0]),
            .reverse => |positions| reverse(pw, positions[0], positions[1]),
            .rotate => |mode| {
                switch (mode) {
                    .amount => |p| rotate(pw, p[1], p[0].rev()),
                    .letter => |char| rotlAtLetter(pw, char),
                }
            },
            .swap => |mode| {
                switch (mode) {
                    .letter => |chars| swapLetters(pw, chars[0], chars[1]),
                    .position => |positions| swap(pw, positions[0], positions[1]),
                }
            },
        }
    }
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
    const amount = if (dir == .right) pw.len - (n % pw.len) else (n % pw.len);
    if (amount == 0) return;
    reverse(pw, 0, amount - 1);
    reverse(pw, amount, pw.len - 1);
    reverse(pw, 0, pw.len - 1);
}

fn rotrAtLetter(pw: []u8, char: u8) void {
    var i: usize = 0;
    while (pw[i] != char) : (i += 1) {}
    var rot = 1 + i;
    if (i >= 4) rot += 1;
    rotate(pw, rot, .right);
}

fn rotlAtLetter(pw: *[8]u8, char: u8) void {
    var i: u3 = 0;
    while (pw[i] != char) : (i += 1) {}
    if (i == 0) {
        rotate(pw, 1, .left);
    } else if (i & 1 == 1) {
        rotate(pw, (i >> 1) + 1, .left);
    } else {
        rotate(pw, 7 - i >> 1, .right);
    }
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
    rotate(&pw, 1, .left);
    try std.testing.expectEqualSlices(u8, "bcdea", &pw);
    move(&pw, 1, 4);
    try std.testing.expectEqualSlices(u8, "bdeac", &pw);
    move(&pw, 3, 0);
    try std.testing.expectEqualSlices(u8, "abdec", &pw);
    rotrAtLetter(&pw, 'b');
    try std.testing.expectEqualSlices(u8, "ecabd", &pw);
    rotrAtLetter(&pw, 'd');
    try std.testing.expectEqualSlices(u8, "decab", &pw);
}
