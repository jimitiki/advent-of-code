const std = @import("std");

const lib = @import("lib");
const Boilerplate = lib.Boilerplate;
const WordIterator = lib.parse.WordIterator;

// TODO: Create a visualization

const Action = enum { toggle, turn };
const State = enum { off, on };
const Instruction = union(Action) {
    toggle: void,
    turn: State,
};
const Position = struct { x: usize, y: usize };

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();
    var lights: [1000][1000]u8 = .{.{0} ** 1000} ** 1000;

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;
    while (try input.takeDelimiter('\n')) |line| {
        var it: WordIterator = .init(line);
        const action: Action = std.meta.stringToEnum(Action, it.next().?) orelse return error.InvalidInput;
        const inst: Instruction = switch (action) {
            .toggle => .{ .toggle = {} },
            .turn => .{ .turn = std.meta.stringToEnum(State, it.next().?) orelse return error.InvalidInput },
        };
        const start = try parsePosition(it.next().?);
        _ = it.next();
        const end = try parsePosition(it.next().?);
        for (lights[start.y .. end.y + 1]) |*row| {
            for (row[start.x .. end.x + 1]) |*light| {
                light.* = switch (bp.part) {
                    .p1 => switch (inst) {
                        .toggle => light.* ^ 1,
                        .turn => |state| if (state == .on) 1 else 0,
                    },
                    .p2 => switch (inst) {
                        .toggle => light.* + 2,
                        .turn => |state| if (state == .on) light.* + 1 else light.* -| 1,
                    },
                };
            }
        }
    }
    var answer: usize = 0;
    for (lights) |row| {
        for (row) |light| {
            answer += light;
        }
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn parsePosition(string: []const u8) !Position {
    const split_point = for (string, 0..) |char, i| {
        if (char == ',') {
            break i;
        }
    } else return error.InvalidInput;
    return .{
        .x = try std.fmt.parseUnsigned(usize, string[0..split_point], 10),
        .y = try std.fmt.parseUnsigned(usize, string[split_point + 1 ..], 10),
    };
}
