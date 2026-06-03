const std = @import("std");

const solver = @import("../solver.zig");

const BitSet = std.bit_set.IntegerBitSet(16);
const Buttons = std.ArrayList(BitSet);

// TODO: Use vectors for joltage computations
// TODO: Stop testing extraneous button presses for part 1
// TODO: Speed up: The current algorithm is bottlenecked by (de)allocations in minPressJolts. Memoization might also have a significant impact.

const Combination = struct {
    const Self = @This();

    pressed: BitSet,
    joltage: []const u16,
    steps: usize,

    pub fn init(
        alloc: std.mem.Allocator,
        pressed: BitSet,
        buttons: []const BitSet,
        light_cnt: usize,
    ) !Self {
        var joltage: []u16 = try alloc.alloc(u16, light_cnt);
        @memset(joltage, 0);
        var steps: usize = 0;
        var it = pressed.iterator(.{});
        while (it.next()) |i| {
            steps += 1;
            var it2 = buttons[i].iterator(.{});
            while (it2.next()) |j| {
                joltage[j] += 1;
            }
        }
        return .{ .pressed = pressed, .joltage = joltage, .steps = steps };
    }

    pub fn deinit(self: Self, alloc: std.mem.Allocator) void {
        alloc.free(self.joltage);
    }

    pub fn parity(self: Self) BitSet {
        var p: BitSet = .empty;
        for (self.joltage, 0..) |jolts, i| {
            if (jolts % 2 == 1) p.set(i);
        }
        return p;
    }

    pub fn format(self: Self, w: *std.Io.Writer) !void {
        return try w.print("{b:0>16}: {any}", .{ self.pressed.mask, self.joltage });
    }
};
const ComboMap = std.AutoHashMapUnmanaged(BitSet, std.ArrayList(Combination));

fn solveInt(tools: solver.Tools) solver.Error!struct { ?usize, ?usize } {
    const gpa = tools.gpa;
    var min_lights: ?usize = 0;
    var min_jolts: ?usize = 0;
    var line_no: u32 = 1;
    while (try tools.input.takeDelimiter('\n')) |line| : (line_no += 1) {
        if (line[0] == '#') continue;
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
        defer buttons.deinit(gpa);
        var start: usize = 0;
        var btn_set: BitSet = undefined;
        const idx: usize = for (line[light_cnt + 2 ..], light_cnt + 2..) |c, i| {
            switch (c) {
                '{' => break i,
                '(' => {
                    start = i + 1;
                    btn_set = .initEmpty();
                },
                ',', ')' => {
                    btn_set.set(std.fmt.parseUnsigned(usize, line[start..i], 10) catch return error.InvalidInput);
                    start = i + 1;
                    if (c == ')') {
                        try buttons.append(gpa, btn_set);
                    }
                },
                else => {},
            }
        } else return error.InvalidInput;

        var jolts: std.ArrayList(u16) = .empty;
        defer jolts.deinit(gpa);
        start = idx + 1;
        for (line[idx..], idx..) |c, i| {
            if (c == '}' or c == ',') {
                try jolts.append(gpa, std.fmt.parseUnsigned(u16, line[start..i], 10) catch return error.InvalidInput);
                start = i + 1;
            }
        }

        if (min_lights) |p| {
            if (try minPressLights(gpa, lights, buttons.items)) |p_add| {
                min_lights = p + p_add;
            } else {
                min_lights = null;
            }
        }

        var combos: ComboMap = .empty;
        defer {
            var it = combos.iterator();
            while (it.next()) |entry| {
                for (entry.value_ptr.items) |combo| combo.deinit(gpa);
                entry.value_ptr.deinit(gpa);
            }
            combos.deinit(gpa);
        }
        for (0..std.math.pow(usize, 2, buttons.items.len)) |i| {
            const combo: Combination = try .init(gpa, .{ .mask = @intCast(i) }, buttons.items, light_cnt);
            const entry = try combos.getOrPutValue(gpa, combo.parity(), .empty);
            try entry.value_ptr.append(gpa, combo);
        }
        if (min_jolts) |j| {
            if (try minPressJolts(gpa, jolts.items, combos, 0)) |j_add| {
                min_jolts = j + j_add;
            } else {
                min_jolts = null;
            }
        }
    }

    return .{ min_lights, min_jolts };
}

pub const solve = solver.intSolver(usize, solveInt);

fn minPressLights(alloc: std.mem.Allocator, expected: BitSet, buttons: []const BitSet) solver.Error!?u64 {
    var step_cnts: std.AutoHashMapUnmanaged(BitSet, usize) = .empty;
    defer step_cnts.deinit(alloc);
    const State = struct { sequence: BitSet, step_cnt: usize };
    var queue: std.Deque(State) = .empty;
    defer queue.deinit(alloc);
    try queue.pushBack(alloc, .{ .sequence = BitSet.initEmpty(), .step_cnt = 0 });
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
    } else {
        return null;
    }
}

fn minPressJolts(
    alloc: std.mem.Allocator,
    expected: []const u16,
    combos: ComboMap,
    depth: usize,
) solver.Error!?u64 {
    for (expected) |jolts| {
        if (jolts != 0) break;
    } else return 0;

    var parity_needed: BitSet = .empty;
    for (expected, 0..) |jolts, i| {
        if (jolts % 2 == 1) parity_needed.set(i);
    }

    if (combos.get(parity_needed)) |cs| {
        var best: usize = std.math.maxInt(usize);
        var found_solution: bool = false;
        const expected_next: []u16 = try alloc.alloc(u16, expected.len);
        defer alloc.free(expected_next);

        test_combo: for (cs.items) |combo| {
            @memset(expected_next, 0);
            for (combo.joltage, 0..) |j, i| {
                if (expected_next[i] + j > expected[i]) continue :test_combo;
                expected_next[i] = (@divExact(expected[i] - j, 2));
            }
            if (try minPressJolts(
                alloc,
                expected_next,
                combos,
                depth + 1,
            )) |steps_next| {
                found_solution = true;
                best = @min(best, combo.steps + steps_next * 2);
            }
        }
        return if (found_solution) best else null;
    } else return null;
}
