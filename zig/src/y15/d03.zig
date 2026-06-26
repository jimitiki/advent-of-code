const std = @import("std");
const lib = @import("lib");

const solver = lib.solver;

const House = struct { x: i32 = 0, y: i32 = 0 };
const HouseSet = std.AutoHashMapUnmanaged(House, void);

// TODO: Create a visualization

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var visited_p1: HouseSet = .empty;
    var visited_p2: HouseSet = .empty;
    defer visited_p1.deinit(tools.gpa);
    defer visited_p2.deinit(tools.gpa);
    var santa1: House = .{};
    var santa2: House = .{};
    var robosanta: House = .{};

    const moves = try input.firstLine();
    try visited_p1.put(tools.gpa, santa1, {});
    try visited_p2.put(tools.gpa, santa2, {});
    for (moves, 0..) |m, i| {
        santa1 = try move(santa1, m);
        try visited_p1.put(tools.gpa, santa1, {});
        if (i & 1 == 0) {
            santa2 = try move(santa2, m);
            try visited_p2.put(tools.gpa, santa2, {});
        } else {
            robosanta = try move(robosanta, m);
            try visited_p2.put(tools.gpa, robosanta, {});
        }
    }
    return .{ visited_p1.size, visited_p2.size };
}

pub const solve = solver.intSolver(u32, solveInt);

fn move(pos: House, char: u8) error{InvalidInput}!House {
    return switch (char) {
        '^' => .{ .x = pos.x, .y = pos.y + 1 },
        'v' => .{ .x = pos.x, .y = pos.y - 1 },
        '>' => .{ .x = pos.x + 1, .y = pos.y },
        '<' => .{ .x = pos.x - 1, .y = pos.y },
        else => return error.InvalidInput,
    };
}
