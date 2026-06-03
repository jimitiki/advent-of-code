const std = @import("std");

const solver = @import("../solver.zig");

const Pos = struct {
    x: usize,
    y: usize,

    fn init(x: usize, y: usize) Pos {
        return .{ .x = x, .y = y };
    }
};

fn compare(_: void, a: struct { Pos, usize }, b: struct { Pos, usize }) std.math.Order {
    return std.math.order(a[1], b[1]);
}

const Queue = std.PriorityQueue(struct { Pos, usize }, void, compare);
const Path = std.ArrayList(Pos);

fn PosMap(comptime V: type) type {
    return std.AutoHashMapUnmanaged(Pos, V);
}

const Dir = enum {
    u,
    d,
    l,
    r,

    pub const dirs = [4]Dir{ .u, .d, .l, .r };

    fn move(self: Dir, pos: Pos) ?Pos {
        return switch (self) {
            .u => if (pos.y > 0) .init(pos.x, pos.y - 1) else null,
            .d => .init(pos.x, pos.y + 1),
            .l => if (pos.x > 0) .init(pos.x - 1, pos.y) else null,
            .r => .init(pos.x + 1, pos.y),
        };
    }
};

fn solveInt(tools: solver.Tools) solver.Error!struct { ?usize, ?usize } {
    const s = try tools.input.takeDelimiter('\n') orelse return error.InvalidInput;
    const seed = std.fmt.parseInt(usize, s, 10) catch return error.InvalidInput;

    var path: std.ArrayList(Pos) = .empty;
    defer path.deinit(tools.gpa);
    const p1 = try aStar(tools.gpa, seed, .init(1, 1), .init(31, 39), &path);
    drawPath(tools.stdout, path.items, seed) catch {};
    return .{ p1, null };
}

pub const solve = solver.intSolver(usize, solveInt);

fn aStar(
    gpa: std.mem.Allocator,
    seed: usize,
    start: Pos,
    goal: Pos,
    path: ?*std.ArrayList(Pos),
) error{OutOfMemory}!?usize {
    var predecessors: PosMap(Pos) = .empty;
    defer predecessors.deinit(gpa);
    var minima: PosMap(usize) = .empty;
    defer minima.deinit(gpa);
    var queue: Queue = .empty;
    defer queue.deinit(gpa);

    try queue.push(gpa, .{ start, distance(start, goal) });
    try minima.put(gpa, start, 0);
    while (queue.pop()) |entry| {
        const cur, _ = entry;
        const dist = minima.get(cur).?;
        if (cur.x == goal.x and cur.y == goal.y) {
            if (path) |steps| {
                var s = cur;
                try steps.append(gpa, cur);
                while (predecessors.get(s)) |p| : (s = p) {
                    try steps.append(gpa, p);
                }
            }
            return dist;
        }

        const new_dist = dist + 1;
        for (Dir.dirs) |dir| {
            const next = dir.move(cur) orelse continue;
            if (getSquare(next.x, next.y, seed)) continue;
            if (new_dist < minima.get(next) orelse std.math.maxInt(usize)) {
                try predecessors.put(gpa, next, cur);
                try minima.put(gpa, next, new_dist);
                try queue.push(gpa, .{ next, new_dist + distance(next, goal) });
            }
        }
    } else return null;
}

test "solve" {
    try std.testing.expectEqual(11, try aStar(std.testing.allocator, 10, .init(1, 1), .init(7, 4), null));
}

fn getSquare(x: usize, y: usize, seed: usize) bool {
    return countBits(x * x + 3 * x + 2 * x * y + y * y + y + seed) & 1 == 1;
}

fn countBits(int: usize) usize {
    var n = int;
    var i: usize = 0;
    while (n > 0) : (i += 1) {
        n &= n - 1;
    }
    return i;
}

test "get square" {
    try std.testing.expect(!getSquare(0, 0, 10));
    try std.testing.expect(getSquare(1, 0, 10));
}

fn distance(a: Pos, b: Pos) usize {
    const x = if (a.x > b.x) a.x - b.x else b.x - a.x;
    const y = if (a.y > b.y) a.y - b.y else b.y - a.y;
    return std.math.sqrt(x * x + y * y);
}

fn drawPath(writer: *std.Io.Writer, path: []Pos, seed: usize) solver.Error!void {
    var xmax: usize = 1;
    var ymax: usize = 1;
    for (path) |pos| {
        xmax = @max(xmax, pos.x);
        ymax = @max(ymax, pos.y);
    }
    xmax += 3;
    ymax += 3;

    try writer.writeAll("   ");
    for (0..xmax) |x| {
        if (x % 2 == 0) {
            try writer.print("{: >2}", .{x});
        } else {
            try writer.writeAll("  ");
        }
    }
    try writer.writeAll("\n");

    try writer.writeAll("  ▗");
    for (0..xmax) |_| try writer.writeAll("▄▄");
    try writer.writeAll("▖\n");

    for (0..ymax) |y| {
        if (y % 2 == 0) {
            try writer.print("{: >2}▐", .{y});
        } else {
            try writer.writeAll("  ▐");
        }
        for (0..xmax) |x| {
            for (path, 0..) |pos, i| {
                if (pos.x != x or pos.y != y) continue;
                if (i == 0) {
                    try writer.writeAll("▓▓");
                } else if (i == path.len - 1) {
                    try writer.writeAll("▓▓");
                } else {
                    try writer.writeAll("▒▒");
                }
                break;
            } else if (getSquare(x, y, seed)) {
                try writer.writeAll("██");
            } else {
                try writer.writeAll("  ");
            }
        }
        if (getSquare(xmax, y, seed)) {
            try writer.writeAll("▌\n");
        } else {
            try writer.writeAll("┊\n");
        }
    }

    try writer.print("  ▝", .{});
    for (0..xmax) |x| {
        if (getSquare(x, ymax, seed)) {
            try writer.print("▀▀", .{});
        } else {
            try writer.print("┉┉", .{});
        }
    }
    if (getSquare(xmax, ymax, seed)) {
        try writer.print("▘\n", .{});
    } else {
        try writer.print("┘\n", .{});
    }
}
