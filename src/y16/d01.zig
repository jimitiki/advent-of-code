const std = @import("std");

const solver = @import("../solver.zig");

// TODO: Implement part 2 by keeping a list of line segments and doing intersection checks. Compare
//     memory usage (should be much less) and speed (probably a bit slower).

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

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var visited: std.AutoHashMapUnmanaged(Position, void) = .empty;
    defer visited.deinit(tools.gpa);

    var direction: Direction = .n;
    var position: Position = .{ .x = 0, .y = 0 };
    var first_revisited: ?Position = null;
    while (try input.reader.takeDelimiter(',')) |step| {
        const move = try parseMove(step);
        direction = direction.turn(move.turn);
        for (0..move.amount) |_| {
            position = direction.walk(position, 1);
            if (first_revisited) |_| {} else {
                const result = try visited.getOrPut(tools.gpa, position);
                if (result.found_existing) {
                    first_revisited = position;
                }
            }
        }
    }
    return .{
        computeDistance(position),
        if (first_revisited) |p| computeDistance(p) else null,
    };
}

pub const solve = solver.intSolver(u32, solveInt);

fn computeDistance(pos: Position) u32 {
    const dist_x: u32 = @intCast(@abs(pos.x));
    const dist_y: u32 = @intCast(@abs(pos.y));

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
