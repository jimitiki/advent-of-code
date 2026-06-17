const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

// TODO: Optimize

const Dir = enum { left, right };
const Action = struct {
    val: bool,
    dir: Dir,
    next: u8,
};
const State = struct {
    f: Action,
    t: Action,
};
const StateTable = std.AutoHashMapUnmanaged(u8, State);
const Tape = struct {
    gpa: std.mem.Allocator,
    queue: std.Deque(bool),
    index: usize,

    pub fn init(gpa: std.mem.Allocator) error{OutOfMemory}!Tape {
        var queue: std.Deque(bool) = .empty;
        try queue.pushBack(gpa, false);
        return .{ .gpa = gpa, .queue = queue, .index = 0 };
    }

    pub fn deinit(self: *Tape) void {
        self.queue.deinit(self.gpa);
    }

    pub fn set(self: *Tape, value: bool) void {
        const ptr = self.queue.atPtr(self.index);
        ptr.* = value;
    }

    pub fn read(self: Tape) bool {
        return self.queue.at(self.index);
    }

    pub fn move(self: *Tape, dir: Dir) error{OutOfMemory}!void {
        switch (dir) {
            .left => try self.moveLeft(),
            .right => try self.moveRight(),
        }
    }

    fn moveLeft(self: *Tape) error{OutOfMemory}!void {
        if (self.index == 0) {
            try self.queue.pushFront(self.gpa, false);
        } else {
            self.index -= 1;
        }
    }

    fn moveRight(self: *Tape) error{OutOfMemory}!void {
        self.index += 1;
        if (self.index == self.queue.len) {
            try self.queue.pushBack(self.gpa, false);
        }
    }

    pub fn count(self: Tape) u32 {
        var cnt: u32 = 0;
        var it = self.queue.iterator();
        while (it.next()) |v| {
            if (v) cnt += 1;
        }
        return cnt;
    }
};

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    const gpa = tools.gpa;
    const start, const step_count, var states = try parseInput(gpa, tools.input.reader);
    defer states.deinit(gpa);

    var i: u32 = 0;
    while (try tools.input.reader.takeDelimiter('\n')) |line| : (i += 1) {
        if (line.len == 0) continue;
        var parser: Parser = .init(line, .{});
        try parser.skipMany(3);
    }
    var tape = try Tape.init(gpa);
    defer tape.deinit();
    var state = start;
    for (0..step_count) |_| {
        state = try step(&tape, states.get(state).?);
    }
    return .{ tape.count(), null };
}

pub const solve = solver.intSolver(u32, solveInt);

fn parseInput(gpa: std.mem.Allocator, input: *std.Io.Reader) solver.Error!struct { u8, u32, StateTable } {
    const start_line = try input.takeDelimiter('\n') orelse return error.InvalidInput;
    var parser: Parser = .init(start_line, .{});
    try parser.skipMany(3);
    const start = try parser.takeByte();

    const step_line = try input.takeDelimiter('\n') orelse return error.InvalidInput;
    parser = .init(step_line, .{});
    try parser.skipMany(5);
    const step_count = try parser.takeInt(u32);

    var states: StateTable = .empty;
    errdefer states.deinit(gpa);
    while (true) {
        _ = input.discardDelimiterInclusive('\n') catch break;
        const line = try input.takeDelimiter('\n') orelse return error.InvalidInput;
        const state = line[9];
        try states.put(gpa, state, .{ .f = try parseAction(input), .t = try parseAction(input) });
    }

    return .{ start, step_count, states };
}

fn parseAction(input: *std.Io.Reader) solver.Error!Action {
    _ = input.discardDelimiterInclusive('\n') catch return error.InvalidInput;
    const val_line = try input.takeDelimiter('\n') orelse return error.InvalidInput;
    var parser: Parser = .init(val_line, .{});
    try parser.skipMany(4);
    const val: bool = switch (try parser.takeByte()) {
        '1' => true,
        '0' => false,
        else => return error.InvalidInput,
    };

    const dir_line = try input.takeDelimiter('\n') orelse return error.InvalidInput;
    parser = .init(dir_line, .{});
    try parser.skipMany(6);
    const dir = try parser.takeEnum(Dir);

    const next_line = try input.takeDelimiter('\n') orelse return error.InvalidInput;
    parser = .init(next_line, .{});
    try parser.skipMany(4);
    const next = try parser.takeByte();

    return .{ .val = val, .dir = dir, .next = next };
}

fn step(tape: *Tape, state: State) error{OutOfMemory}!u8 {
    const action = if (tape.read()) state.t else state.f;
    tape.set(action.val);
    try tape.move(action.dir);
    return action.next;
}
