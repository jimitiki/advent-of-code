const std = @import("std");

const solver = @import("../solver.zig");

const House = struct { x: i32 = 0, y: i32 = 0 };
const HouseSet = std.AutoHashMapUnmanaged(House, void);

// TODO: Create a visualization

fn solveInt(gpa: std.mem.Allocator, input: *std.Io.Reader) solver.Error!struct { ?u32, ?u32 } {
    var visited_p1: HouseSet = .empty;
    var visited_p2: HouseSet = .empty;
    defer visited_p1.deinit(gpa);
    defer visited_p2.deinit(gpa);
    var santa1: House = .{};
    var santa2: House = .{};
    var robosanta: House = .{};

    while (true) {
        visited_p1.put(gpa, santa1, {}) catch unreachable;
        visited_p2.put(gpa, santa2, {}) catch unreachable;
        if (input.takeByte()) |char| {
            if (char == '\n') break;
            santa1 = try move(santa1, char);
            santa2 = try move(santa2, char);
        } else |_| break;
        visited_p1.put(gpa, santa1, {}) catch unreachable;
        visited_p2.put(gpa, robosanta, {}) catch unreachable;
        if (input.takeByte()) |char| {
            if (char == '\n') break;
            santa1 = try move(santa1, char);
            robosanta = try move(robosanta, char);
        } else |_| break;
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
