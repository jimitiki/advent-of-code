const std = @import("std");

const solver = @import("../solver.zig");

const Move = struct {
    pub const Turn = enum { l, r };

    turn: Turn,
    amount: u8,

    const Self = @This();
};
const Direction = enum(u2) {
    n = 0,
    e = 1,
    s = 2,
    w = 3,

    const Self = @This();

    pub fn turn(self: Self, t: Move.Turn) Self {
        return switch (t) {
            .l => @enumFromInt(@intFromEnum(self) +% 1),
            .r => @enumFromInt(@intFromEnum(self) -% 1),
        };
    }

    pub fn walk(self: Self, position: Position, amount: u8) Position {
        return switch (self) {
            .n => .{ .x = position.x, .y = position.y + amount },
            .e => .{ .x = position.x + amount, .y = position.y },
            .s => .{ .x = position.x, .y = position.y - amount },
            .w => .{ .x = position.x - amount, .y = position.y },
        };
    }
};
const Position = struct { x: i32, y: i32 };

fn solveInt(_: std.mem.Allocator, input: *std.Io.Reader) solver.Error!struct { ?u32, ?u32 } {
    var direction: Direction = .n;
    var position: Position = .{ .x = 0, .y = 0 };
    while (try input.takeDelimiter(',')) |step| {
        const move = try parseMove(step);
        direction = direction.turn(move.turn);
        position = direction.walk(position, move.amount);
    }
    return .{ computeDistance(.{ .x = 0, .y = 0 }, position), null };
}

pub const solve = solver.intSolver(u32, solveInt);

fn computeDistance(pos1: Position, pos2: Position) u32 {
    const dist_x: u32 = @intCast(if (pos1.x > pos2.x) pos1.x - pos2.x else pos2.x - pos1.x);
    const dist_y: u32 = @intCast(if (pos1.y > pos2.y) pos1.y - pos2.y else pos2.y - pos1.y);

    return dist_x + dist_y;
}

fn parseMove(str: []const u8) error{InvalidInput}!Move {
    if (str[0] == ' ') {
        return parseMove(str[1..]);
    } else if (str[str.len - 1] == '\n') {
        return parseMove(str[0 .. str.len - 1]);
    } else {
        return .{
            .turn = if (str[0] == 'L') .l else if (str[0] == 'R') .r else return error.InvalidInput,
            .amount = std.fmt.parseInt(u8, str[1..], 10) catch return error.InvalidInput,
        };
    }
}
