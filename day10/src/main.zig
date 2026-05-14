const std = @import("std");

const Init = @import("lib").Init;

const BitSet = std.bit_set.IntegerBitSet(16);
const Buttons = std.ArrayList(BitSet);

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var ini = try Init.init(init, &stdout_buffer, &read_buffer);
    defer ini.deinit();

    var stdout = &ini.stdout_writer.interface;
    var input = &ini.input_reader.interface;
    var answer: usize = 0;
    while (try input.takeDelimiter('\n')) |line| {
        if (line[0] != '[') return error.InvalidInput;
        const light_cnt: usize = for (line[1..], 1..) |c, i| {
            if (c == ']') break i - 1;
        } else return error.InvalidInput;

        var lights: BitSet = .initEmpty();
        for (line[1 .. light_cnt + 1], 0..) |light, i| {
            switch (light) {
                '#' => lights.set(i),
                '.' => {},
                else => return error.InvalidInput,
            }
        }

        var buttons: Buttons = .empty;
        var start: usize = 0;
        var btn_set: BitSet = undefined;
        for (line[light_cnt + 2 ..], light_cnt + 2..) |c, i| {
            switch (c) {
                '{' => break,
                '(' => {
                    start = i + 1;
                    btn_set = .initEmpty();
                },
                ',', ')' => {
                    btn_set.set(try std.fmt.parseUnsigned(usize, line[start..i], 10));
                    start = i + 1;
                    if (c == ')') {
                        try buttons.append(ini.arena, btn_set);
                    }
                },
                else => {},
            }
        }
        answer += try minPresses(ini.arena, lights, buttons.items);
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn minPresses(alloc: std.mem.Allocator, expected: BitSet, buttons: []const BitSet) !u64 {
    var step_cnts: std.AutoHashMapUnmanaged(BitSet, usize) = .empty;
    const State = struct { sequence: BitSet, step_cnt: usize };
    const starting_state: State = .{ .sequence = BitSet.initEmpty(), .step_cnt = 0 };
    var queue: std.Deque(State) = .empty;
    try queue.pushBack(alloc, starting_state);

    while (queue.popFront()) |state| {
        if (step_cnts.get(state.sequence)) |step_cnt| {
            if (step_cnt <= state.step_cnt) continue;
        }
        try step_cnts.put(alloc, state.sequence, state.step_cnt);
        for (buttons) |button| {
            try queue.pushBack(alloc, .{
                .sequence = state.sequence.xorWith(button),
                .step_cnt = state.step_cnt + 1,
            });
        }
    }
    if (step_cnts.get(expected)) |step_cnt| {
        return step_cnt;
    } else @panic("Failed to find a solution");
}
