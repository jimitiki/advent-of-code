const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

const Transform = struct {
    final: [9]u9,
    cnt3: u8,
    cnt4: u8,
    cnt6: u8,
};

const State = struct {
    start: u9,
    iterations: u8,
};

const RuleTable2 = std.AutoHashMapUnmanaged(u4, [3][3]u1);
const TransformTable = std.AutoHashMapUnmanaged(u9, Transform);
const Memo = std.AutoHashMapUnmanaged(State, u32);

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    const gpa = tools.gpa;
    var rules2: RuleTable2 = .empty;
    defer rules2.deinit(gpa);
    var transforms: TransformTable = .empty;
    defer transforms.deinit(gpa);

    var line = try tools.input.takeDelimiter('\n') orelse return error.InvalidInput;
    while (line.len == 20) : (line = try tools.input.takeDelimiter('\n') orelse "") {
        var parser: Parser = .init(line, .{ .skip_punctuation = false });
        const pattern = try parser.take();
        try parser.skip();
        const result = try parser.take();
        const in = try fillGrid(2, pattern);
        const out = try fillGrid(3, result);
        for (0..4) |n| {
            try rules2.put(gpa, rotate2(in, @intCast(n)), out);
        }
    }
    while (line.len == 34) : (line = try tools.input.takeDelimiter('\n') orelse "") {
        var parser: Parser = .init(line, .{ .skip_punctuation = false });
        const pattern = try parser.take();
        try parser.skip();
        const result = try parser.take();
        const start = try fillGrid(3, pattern);
        const sq4 = try fillGrid(4, result);

        var sq6: [6][6]u1 = undefined;
        for (0..2) |i| {
            for (0..2) |j| {
                const u = i * 2;
                const v = j * 2;
                const sub = extract4(sq4[u][v], sq4[u][v + 1], sq4[u + 1][v], sq4[u + 1][v + 1]);
                const sq3 = rules2.get(sub).?;
                for (0..3) |k| {
                    @memcpy(sq6[i * 3 + k][j * 3 .. (j + 1) * 3], &sq3[k]);
                }
            }
        }

        var final: [9]u9 = undefined;
        var cnt9: u8 = 0;
        for (0..3) |i| {
            for (0..3) |j| {
                const u = i * 2;
                const v = j * 2;
                const sub = extract4(sq6[u][v], sq6[u][v + 1], sq6[u + 1][v], sq6[u + 1][v + 1]);
                const sq3 = rules2.get(sub).?;
                const n = extract9(sq3);
                final[i * 3 + j] = n;
                cnt9 += @popCount(n);
            }
        }

        const transform: Transform = .{ .cnt3 = count(start), .cnt4 = count(sq4), .cnt6 = count(sq6), .final = final };
        for (0..2) |f| {
            for (0..4) |n| {
                try transforms.put(gpa, rotate3(start, @intCast(n), f == 1), transform);
            }
        }
    }

    var memo: Memo = .empty;
    defer memo.deinit(gpa);
    const start: u9 = 0b010_100_111;
    return .{
        try iterate(gpa, transforms, &memo, start, 5),
        try iterate(gpa, transforms, &memo, start, 18),
    };
}

pub const solve = solver.intSolver(u32, solveInt);

fn iterate(
    gpa: std.mem.Allocator,
    transforms: TransformTable,
    memo: *Memo,
    start: u9,
    n: u8,
) error{OutOfMemory}!u32 {
    const state: State = .{ .start = start, .iterations = n };
    if (memo.get(state)) |m| {
        return m;
    }
    const transform = transforms.get(start).?;
    const sum = switch (n) {
        0 => transform.cnt3,
        1 => transform.cnt4,
        2 => transform.cnt6,
        else => try sumChildren(gpa, transforms, memo, transform, n - 3),
    };
    try memo.put(gpa, state, sum);
    return sum;
}

fn sumChildren(
    gpa: std.mem.Allocator,
    transforms: TransformTable,
    memo: *Memo,
    transform: Transform,
    n: u8,
) error{OutOfMemory}!u32 {
    var sum: u32 = 0;
    for (transform.final) |next| {
        sum += try iterate(gpa, transforms, memo, next, n);
    }
    return sum;
}

fn count(grid: anytype) u8 {
    var cnt: u8 = 0;
    for (grid) |row| {
        for (row) |cell| cnt += cell;
    }
    return cnt;
}

fn extract4(a: u1, b: u1, c: u1, d: u1) u4 {
    var n: u4 = 0;
    if (a == 1) n |= 8;
    if (b == 1) n |= 4;
    if (c == 1) n |= 2;
    if (d == 1) n |= 1;
    return n;
}

fn extract9(grid: [3][3]u1) u9 {
    var n: u9 = 0;
    for (0..3) |i| {
        for (0..3) |j| {
            if (grid[i][j] == 1) n |= @as(u9, 1) << @intCast(8 - (i * 3 + j));
        }
    }
    return n;
}

fn fillGrid(comptime n: usize, pattern: []const u8) error{InvalidInput}![n][n]u1 {
    var grid: [n][n]u1 = undefined;
    var i: u8 = 0;
    var j: u8 = 0;
    for (pattern) |char| {
        switch (char) {
            '#' => grid[i][j] = 1,
            '.' => grid[i][j] = 0,
            '/' => {
                i += 1;
                j = 0;
                continue;
            },
            else => return error.InvalidInput,
        }
        j += 1;
    }
    return grid;
}

fn rotate2(start: [2][2]u1, n: u2) u4 {
    var result = start;
    switch (n) {
        0 => {},
        1 => {
            const temp = result[0][0];
            result[0][0] = result[1][0];
            result[1][0] = result[1][1];
            result[1][1] = result[0][1];
            result[0][1] = temp;
        },
        2 => {
            std.mem.swap([2]u1, &result[0], &result[1]);
            for (&result) |*row| std.mem.reverse(u1, row);
        },
        3 => {
            const temp = result[0][0];
            result[0][0] = result[0][1];
            result[0][1] = result[1][1];
            result[1][1] = result[1][0];
            result[1][0] = temp;
        },
    }
    return extract4(result[0][0], result[0][1], result[1][0], result[1][1]);
}

fn rotate3(start: [3][3]u1, n: u2, flip: bool) u9 {
    var result = start;
    if (flip) {
        for (0..3) |i| {
            const temp = result[i][0];
            result[i][0] = result[i][2];
            result[i][1] = result[i][1];
            result[i][2] = temp;
        }
    }
    switch (n) {
        0 => {},
        1 => {
            const tempa = result[0][0];
            result[0][0] = result[2][0];
            result[2][0] = result[2][2];
            result[2][2] = result[0][2];
            result[0][2] = tempa;

            const tempb = result[0][1];
            result[0][1] = result[1][0];
            result[1][0] = result[2][1];
            result[2][1] = result[1][2];
            result[1][2] = tempb;
        },
        2 => {
            std.mem.swap([3]u1, &result[0], &result[2]);
            for (&result) |*row| std.mem.reverse(u1, row);
        },
        3 => {
            const tempa = result[0][0];
            result[0][0] = result[0][2];
            result[0][2] = result[2][2];
            result[2][2] = result[2][0];
            result[2][0] = tempa;

            const tempb = result[0][1];
            result[0][1] = result[1][2];
            result[1][2] = result[2][1];
            result[2][1] = result[1][0];
            result[1][0] = tempb;
        },
    }
    return extract9(result);
}
