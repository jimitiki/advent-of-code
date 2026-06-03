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

fn solveInt(gpa: std.mem.Allocator, input: *std.Io.Reader) solver.Error!struct { ?usize, ?usize } {
    const s = try input.takeDelimiter('\n') orelse return error.InvalidInput;
    const seed = std.fmt.parseInt(usize, s, 10) catch return error.InvalidInput;
    return .{
        try minSteps(gpa, seed, .init(1, 1), .init(31, 39)),
        null,
    };
}

fn minSteps(gpa: std.mem.Allocator, seed: usize, start: Pos, goal: Pos) error{OutOfMemory}!?usize {
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
            return minima.get(cur).?;
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
    try std.testing.expectEqual(11, try minSteps(std.testing.allocator, 10, .init(1, 1), .init(7, 4)));
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

pub const solve = solver.intSolver(usize, solveInt);
