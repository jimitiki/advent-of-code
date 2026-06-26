const std = @import("std");
const lib = @import("lib");

const solver = lib.solver;
const Parser = lib.Parser;

// TODO: Create a visualization

const Action = enum { toggle, turn };
const State = enum { off, on };
const Instruction = union(Action) {
    toggle: void,
    turn: State,
};
const Position = struct { x: usize, y: usize };

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?usize, ?usize } {
    _ = tools;
    var lights1: [1000][1000]u8 = .{.{0} ** 1000} ** 1000;
    var lights2: [1000][1000]u8 = .{.{0} ** 1000} ** 1000;
    var reader = input.reader();
    while (try reader.takeDelimiter('\n')) |line| {
        var parser: Parser = .init(line, .{});
        const action = try parser.takeEnum(Action);
        const inst: Instruction = switch (action) {
            .toggle => .{ .toggle = {} },
            .turn => .{ .turn = try parser.takeEnum(State) },
        };
        const start: Position = .{
            .x = try parser.takeInt(usize),
            .y = try parser.takeInt(usize),
        };
        try parser.skip();
        const end: Position = .{
            .x = try parser.takeInt(usize),
            .y = try parser.takeInt(usize),
        };
        for (lights1[start.y .. end.y + 1]) |*row| {
            for (row[start.x .. end.x + 1]) |*light| {
                light.* = switch (inst) {
                    .toggle => light.* ^ 1,
                    .turn => |state| if (state == .on) 1 else 0,
                };
            }
        }
        for (lights2[start.y .. end.y + 1]) |*row| {
            for (row[start.x .. end.x + 1]) |*light| {
                light.* = switch (inst) {
                    .toggle => light.* + 2,
                    .turn => |state| if (state == .on) light.* + 1 else light.* -| 1,
                };
            }
        }
    }
    var answer1: usize = 0;
    for (lights1) |row| {
        for (row) |light| {
            answer1 += light;
        }
    }
    var answer2: usize = 0;
    for (lights2) |row| {
        for (row) |light| {
            answer2 += light;
        }
    }
    return .{ answer1, answer2 };
}

pub const solve = solver.intSolver(usize, solveInt);

fn parsePosition(string: []const u8) error{InvalidInput}!Position {
    const split_point = for (string, 0..) |char, i| {
        if (char == ',') {
            break i;
        }
    } else return error.InvalidInput;
    return .{
        .x = std.fmt.parseUnsigned(usize, string[0..split_point], 10) catch return error.InvalidInput,
        .y = std.fmt.parseUnsigned(usize, string[split_point + 1 ..], 10) catch return error.InvalidInput,
    };
}
