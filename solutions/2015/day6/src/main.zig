const std = @import("std");

const Boilerplate = @import("boilerplate").Boilerplate;

const Action = enum { toggle, turn };
const State = enum { off, on };
const Instruction = union(Action) {
    toggle: void,
    turn: State,
};
const Row = std.bit_set.ArrayBitSet(usize, 1000);
const Position = struct { x: usize, y: usize };

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();
    var lights = [_]Row{.empty} ** 1000;

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;
    while (try input.takeDelimiter('\n')) |line| {
        var index: usize = 0;
        const action: Action = std.meta.stringToEnum(Action, getNextWord(line, &index)) orelse return error.InvalidInput;
        const inst: Instruction = switch (action) {
            .toggle => .{ .toggle = {} },
            .turn => .{ .turn = std.meta.stringToEnum(State, getNextWord(line, &index)) orelse return error.InvalidInput },
        };
        const start = try parsePosition(getNextWord(line, &index));
        _ = getNextWord(line, &index);
        const end = try parsePosition(getNextWord(line, &index));
        const rows: []Row = lights[start.y .. end.y + 1];
        const range: std.bit_set.Range = .{ .start = start.x, .end = end.x + 1 };
        switch (inst) {
            .toggle => {
                var mask: Row = .empty;
                mask.setRangeValue(range, true);
                for (rows) |*row| {
                    row.toggleSet(mask);
                }
            },
            .turn => |state| {
                const value = state == .on;
                for (rows) |*row| {
                    row.setRangeValue(range, value);
                }
            },
        }
    }
    var answer: usize = 0;
    for (lights) |row| {
        answer += row.count();
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

fn getNextWord(string: []const u8, index: *usize) []const u8 {
    while (index.* < string.len and string[index.*] == ' ') : (index.* += 1) {}
    const start = index.*;
    while (index.* < string.len and string[index.*] != ' ') : (index.* += 1) {}
    return string[start..index.*];
}
