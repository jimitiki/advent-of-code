const std = @import("std");

const solver = @import("../solver.zig");
const t = @import("../test.zig");

const Dir = enum { d, l, r, u };
const Pos = struct { x: usize, y: usize };

pub fn solve(tools: solver.Tools) solver.Error!solver.Result {
    const gpa = tools.gpa;
    var line_list: std.ArrayList([]const u8) = .empty;
    defer {
        for (line_list.items) |line| gpa.free(line);
        line_list.deinit(gpa);
    }
    while (try tools.input.takeDelimiter('\n')) |line| {
        const l = try gpa.alloc(u8, line.len);
        @memcpy(l, line);
        try line_list.append(gpa, l);
    }

    const map = line_list.items;
    const xstart: usize = for (map[0], 0..) |char, x| {
        if (char == '|' or char == '+') break x;
    } else return error.InvalidInput;

    var pos: ?Pos = .{ .x = xstart, .y = 0 };
    var dir: Dir = .d;
    var letter_count: usize = 0;
    while (pos) |p| {
        const char = map[p.y][p.x];
        if (char == '+') {
            dir, pos = turn(map, dir, p);
            continue;
        } else if (char >= 'A' and char <= 'Z') {
            tools.p1buf[letter_count] = char;
            letter_count += 1;
        } else if (char != '|' and char != '-') {
            return error.InvalidInput;
        }
        pos = move(map, dir, p);
    }

    return .{ tools.p1buf[0..letter_count], null };
}

test "solve" {
    const input =
        \\    |
        \\    |  +--+
        \\    A  |  C
        \\F---|----E|--+
        \\    |  |  |  D
        \\    +B-+  +--+
    ;
    try t.expectSolution(solve, .{ "ABCDEF", null }, input);
}

fn turn(map: []const []const u8, dir: Dir, pos: Pos) struct { Dir, Pos } {
    const a, const b = switch (dir) {
        .d, .u => .{ Dir.l, Dir.r },
        .l, .r => .{ Dir.d, Dir.u },
    };

    if (move(map, a, pos)) |next| {
        return .{ a, next };
    } else if (move(map, b, pos)) |next| {
        return .{ b, next };
    } else unreachable;
}

fn move(map: []const []const u8, dir: Dir, pos: Pos) ?Pos {
    const next: Pos = switch (dir) {
        .d => .{ .x = pos.x, .y = pos.y + 1 },
        .l => .{ .x = pos.x -% 1, .y = pos.y },
        .r => .{ .x = pos.x + 1, .y = pos.y },
        .u => .{ .x = pos.x, .y = pos.y -% 1 },
    };
    if (next.y >= map.len or next.x >= map[next.y].len) {
        return null;
    } else if (map[next.y][next.x] == ' ') {
        return null;
    } else {
        return next;
    }
}
