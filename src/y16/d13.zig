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

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?usize, ?usize } {
    const s = try input.reader.takeDelimiter('\n') orelse return error.InvalidInput;
    const seed = std.fmt.parseInt(usize, s, 10) catch return error.InvalidInput;

    var path: std.ArrayList(Pos) = .empty;
    defer path.deinit(tools.gpa);
    const p1 = try aStar(tools.gpa, seed, .init(1, 1), .init(31, 39), &path);

    var visited: PosMap(usize) = .empty;
    defer visited.deinit(tools.gpa);
    const p2 = try scan(tools.gpa, &visited, seed, .init(1, 1), 50);

    drawMaze(tools.stdout, path.items, visited, seed) catch {};
    return .{ p1, p2 };
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
    var pos_buf: [4]Pos = undefined;

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
        for (generateNext(&pos_buf, cur, seed)) |next| {
            if (new_dist < minima.get(next) orelse std.math.maxInt(usize)) {
                try predecessors.put(gpa, next, cur);
                try minima.put(gpa, next, new_dist);
                try queue.push(gpa, .{ next, new_dist + distance(next, goal) });
            }
        }
    } else return null;
}

test "a*" {
    try std.testing.expectEqual(11, try aStar(std.testing.allocator, 10, .init(1, 1), .init(7, 4), null));
}

fn scan(gpa: std.mem.Allocator, visited: *PosMap(usize), seed: usize, start: Pos, limit: usize) error{OutOfMemory}!usize {
    var queue: Queue = .empty;
    defer queue.deinit(gpa);
    var pos_buf: [4]Pos = undefined;

    try visited.put(gpa, start, 0);
    try queue.push(gpa, .{ start, 0 });
    while (queue.pop()) |entry| {
        if (entry[1] == limit) continue;
        const cur, const dist = entry;
        const new_dist = dist + 1;
        for (generateNext(&pos_buf, cur, seed)) |next| {
            if (new_dist < visited.get(next) orelse std.math.maxInt(usize)) {
                try visited.put(gpa, next, new_dist);
                try queue.push(gpa, .{ next, new_dist });
            }
        }
    }
    return visited.size;
}

fn generateNext(buf: *[4]Pos, start: Pos, seed: usize) []Pos {
    var i: usize = 0;
    if (start.y > 0 and !getSquare(start.x, start.y - 1, seed)) {
        buf[i] = .init(start.x, start.y - 1);
        i += 1;
    }
    if (start.x > 0 and !getSquare(start.x - 1, start.y, seed)) {
        buf[i] = .init(start.x - 1, start.y);
        i += 1;
    }
    if (!getSquare(start.x, start.y + 1, seed)) {
        buf[i] = .init(start.x, start.y + 1);
        i += 1;
    }
    if (!getSquare(start.x + 1, start.y, seed)) {
        buf[i] = .init(start.x + 1, start.y);
        i += 1;
    }
    return buf[0..i];
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

fn drawMaze(writer: *std.Io.Writer, path: []const Pos, visited: PosMap(usize), seed: usize) error{WriteFailed}!void {
    var xmax1: usize = 4;
    var ymax1: usize = 4;
    for (path) |pos| {
        xmax1 = @max(xmax1, pos.x + 3);
        ymax1 = @max(ymax1, pos.y + 3);
    }

    var xmax2: usize = 4;
    var ymax2: usize = 4;
    var it = visited.keyIterator();
    while (it.next()) |pos| {
        xmax2 = @max(xmax2, pos.x + 3);
        ymax2 = @max(ymax2, pos.y + 3);
    }

    const gap = 8;
    try drawTop(writer, xmax1, xmax2, gap);

    for (0..@max(ymax1, ymax2) + 1) |y| {
        if (y < ymax1) {
            try drawYAxis(writer, y, gap);
            try drawPathRow(writer, path, seed, xmax1, y);
            try drawRightEdge(writer, seed, xmax1, y);
        } else if (y == ymax1) {
            try drawBottom(writer, seed, xmax1, y, gap);
        } else {
            for (0..xmax1 + gap + 3) |_| try writer.writeAll(" ");
        }
        if (y < ymax2) {
            try drawYAxis(writer, y, gap);
            try drawScanRow(writer, visited, seed, xmax2, y);
            try drawRightEdge(writer, seed, xmax2, y);
        } else if (y == ymax2) {
            try drawBottom(writer, seed, xmax2, y, gap);
        }
        try writer.writeAll("\n");
    }
    try writer.flush();
}

fn drawTop(writer: *std.Io.Writer, xmax1: usize, xmax2: usize, gap: usize) error{WriteFailed}!void {
    for (0..gap) |_| try writer.writeAll(" ");
    try writer.writeAll("   ");
    try drawXLabels(writer, xmax1);
    for (0..gap) |_| try writer.writeAll(" ");
    try writer.writeAll("   ");
    try drawXLabels(writer, xmax2);
    try writer.writeAll("\n");

    for (0..gap) |_| try writer.writeAll(" ");
    try writer.writeAll("  ▗");
    for (0..xmax1) |_| try writer.writeAll("▄▄");
    try writer.writeAll("▖");
    for (0..gap) |_| try writer.writeAll(" ");
    try writer.writeAll("  ▗");
    for (0..xmax2) |_| try writer.writeAll("▄▄");
    try writer.writeAll("▖\n");
}

fn drawPathRow(writer: *std.Io.Writer, path: []const Pos, seed: usize, xmax: usize, y: usize) error{WriteFailed}!void {
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
        } else try drawTile(writer, seed, x, y);
    }
}

fn drawScanRow(writer: *std.Io.Writer, visited: PosMap(usize), seed: usize, xmax: usize, y: usize) error{WriteFailed}!void {
    for (0..xmax) |x| {
        if (x == 1 and y == 1) {
            try writer.writeAll("▓▓");
        } else if (visited.contains(.init(x, y))) {
            try writer.writeAll("▒▒");
        } else try drawTile(writer, seed, x, y);
    }
}

fn drawBottom(writer: *std.Io.Writer, seed: usize, xmax: usize, y: usize, gap: usize) error{WriteFailed}!void {
    for (0..gap) |_| try writer.writeAll(" ");
    try writer.print("  ▝", .{});
    for (0..xmax) |x| {
        if (getSquare(x, y, seed)) {
            try writer.print("▀▀", .{});
        } else {
            try writer.print("┉┉", .{});
        }
    }
    if (getSquare(xmax, y, seed)) {
        try writer.print("▘", .{});
    } else {
        try writer.print("┘", .{});
    }
}

fn drawXLabels(writer: *std.Io.Writer, xmax: usize) error{WriteFailed}!void {
    for (0..xmax) |x| {
        if (x % 2 == 0) {
            try writer.print("{: >2}", .{x});
        } else {
            try writer.writeAll("  ");
        }
    }
}

fn drawYAxis(writer: *std.Io.Writer, y: usize, gap: usize) error{WriteFailed}!void {
    for (0..gap) |_| try writer.writeAll(" ");
    if (y % 2 == 0) {
        try writer.print("{: >2}▐", .{y});
    } else {
        try writer.writeAll("  ▐");
    }
}

fn drawTile(writer: *std.Io.Writer, seed: usize, x: usize, y: usize) error{WriteFailed}!void {
    if (getSquare(x, y, seed)) {
        try writer.writeAll("██");
    } else {
        try writer.writeAll("  ");
    }
}

fn drawRightEdge(writer: *std.Io.Writer, seed: usize, x: usize, y: usize) error{WriteFailed}!void {
    if (getSquare(x, y, seed)) {
        try writer.writeAll("▌");
    } else {
        try writer.writeAll("┊");
    }
}
