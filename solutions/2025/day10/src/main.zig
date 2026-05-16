const std = @import("std");

const Init = @import("lib").Init;

const BitSet = std.bit_set.IntegerBitSet(16);
const Buttons = std.ArrayList(BitSet);

const ArrayHashContext = struct {
    pub fn hash(self: @This(), a: []const u16) u64 {
        _ = self;
        var hasher = std.hash.Wyhash.init(0);
        std.hash.autoHashStrat(&hasher, a, .Deep);
        return hasher.final();
    }
    pub fn eql(self: @This(), a: []const u16, b: []const u16) bool {
        _ = self;
        return std.meta.eql(a, b);
    }
};
const JoltsCache = std.HashMapUnmanaged([]const u16, usize, ArrayHashContext, 80);
const BitSetCache = std.AutoHashMapUnmanaged(BitSet, usize);

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

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var ini = try Init.init(init, &stdout_buffer, &read_buffer);
    defer ini.deinit();

    var stdout = &ini.stdout_writer.interface;
    var input = &ini.input_reader.interface;
    var answer: usize = 0;
    while (try input.takeDelimiter('\n')) |line| {
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
                    btn_set.set(try std.fmt.parseUnsigned(usize, line[start..i], 10));
                    start = i + 1;
                    if (c == ')') {
                        try buttons.append(ini.arena, btn_set);
                    }
                },
                else => {},
            }
        } else return error.InvalidInput;

        var jolts: std.ArrayList(u16) = .empty;
        defer jolts.deinit(ini.arena);
        start = idx + 1;
        for (line[idx..], idx..) |c, i| {
            if (c == '}' or c == ',') {
                try jolts.append(ini.arena, try std.fmt.parseUnsigned(u16, line[start..i], 10));
                start = i + 1;
            }
        }
        if (ini.part == .p1) {
            answer += try minPressLights(ini.arena, lights, buttons.items);
        } else {
            var combos: ComboMap = .empty;
            defer combos.deinit(ini.arena);
            for (0..std.math.pow(usize, 2, buttons.items.len)) |i| {
                const combo: Combination = try .init(ini.arena, .{ .mask = @intCast(i) }, buttons.items, light_cnt);
                const entry = try combos.getOrPutValue(ini.arena, combo.parity(), .empty);
                try entry.value_ptr.append(ini.arena, combo);
            }
            answer += try minPressJolts(ini.arena, jolts.items, combos, 0) orelse return error.Unsolvable;
        }
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn minPressLights(alloc: std.mem.Allocator, expected: BitSet, buttons: []const BitSet) !u64 {
    var step_cnts: std.AutoHashMapUnmanaged(BitSet, usize) = .empty;
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
    } else @panic("Failed to find a solution");
}
fn minPressJolts(
    alloc: std.mem.Allocator,
    expected: []const u16,
    combos: ComboMap,
    depth: usize,
) !?u64 {
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
        test_combo: for (cs.items) |combo| {
            const expected_next: []u16 = try alloc.alloc(u16, expected.len);
            defer alloc.free(expected_next);
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
