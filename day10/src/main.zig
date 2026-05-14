const std = @import("std");

const Init = @import("lib").Init;

const State = struct {
    lights: BitSet,
    step_cnt: usize,
};

const BitSet = std.bit_set.IntegerBitSet(16);
const Buttons = std.ArrayList(BitSet);
const StepMap = std.AutoHashMapUnmanaged(BitSet, usize);
const StateQueue = std.Deque(State);

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

        var pattern: BitSet = .initEmpty();
        for (line[1 .. light_cnt + 1], 0..) |light, i| {
            switch (light) {
                '#' => pattern.set(i),
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

        var step_cnts: StepMap = .empty;
        var queue: StateQueue = .empty;
        const starting_state: State = .{ .lights = .initEmpty(), .step_cnt = 0 };
        try queue.pushBack(ini.arena, starting_state);

        while (queue.popFront()) |state| {
            if (step_cnts.get(state.lights)) |step_cnt| {
                if (step_cnt <= state.step_cnt) continue;
            }
            try step_cnts.put(ini.arena, state.lights, state.step_cnt);
            for (buttons.items) |button| {
                try queue.pushBack(ini.arena, .{
                    .lights = state.lights.xorWith(button),
                    .step_cnt = state.step_cnt + 1,
                });
            }
        }
        if (step_cnts.get(pattern)) |step_cnt| {
            answer += step_cnt;
        } else @panic("Failed to find a solution");
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}
