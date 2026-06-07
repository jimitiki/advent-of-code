const std = @import("std");

const solver = @import("../solver.zig");

const Position = struct {
    x: usize,
    y: usize,
};

fn Maze(comptime n: u8) type {
    return struct {
        const Self = @This();
        const BitSetInt = @Int(.unsigned, n);
        const wire_count = n;
        const goal = std.math.maxInt(BitSetInt);

        pub const State = struct {
            pos: Position,
            visited: BitSetInt = 0,

            pub fn finished(self: State) bool {
                return self.visited == goal;
            }
        };

        layout: [][]u8,
        rowlist: std.ArrayList([]u8),

        pub fn parse(gpa: std.mem.Allocator, reader: *std.Io.Reader) solver.Error!struct { Self, Position } {
            const width = (reader.peekDelimiterExclusive('\n') catch return error.InvalidInput).len;
            var rows: std.ArrayList([]u8) = .empty;
            var start: Position = undefined;
            var y: usize = 0;
            while (try reader.takeDelimiter('\n')) |line| : (y += 1) {
                if (line.len != width) return error.InvalidInput;
                var row = try gpa.alloc(u8, width);
                for (line, 0..) |char, x| {
                    row[x] = char;
                    if (char == '0') {
                        start = .{ .x = x, .y = y };
                    }
                }
                try rows.append(gpa, row);
            }

            return .{ .{ .layout = rows.items, .rowlist = rows }, start };
        }

        pub fn deinit(self: *Self, gpa: std.mem.Allocator) void {
            for (self.layout) |row| gpa.free(row);
            self.rowlist.deinit(gpa);
        }

        fn shortestPath(self: Self, gpa: std.mem.Allocator, start: Position) error{OutOfMemory}!?u16 {
            var queue: std.PriorityQueue(struct { u16, State }, void, cmp) = .empty;
            defer queue.deinit(gpa);
            var minima: std.AutoHashMapUnmanaged(State, u16) = .empty;
            defer minima.deinit(gpa);
            var state_buf: [4]State = undefined;

            const initial: State = .{ .pos = start, .visited = 0 };
            try queue.push(gpa, .{ 0, initial });
            try minima.put(gpa, initial, 0);

            while (queue.pop()) |entry| {
                const dist, const state = entry;
                if (state.finished()) return dist;
                const new_dist = dist + 1;
                for (self.generateStates(state, &state_buf)) |next| {
                    if (new_dist >= minima.get(next) orelse std.math.maxInt(u16)) continue;
                    try minima.put(gpa, next, new_dist);
                    try queue.push(gpa, .{ new_dist, next });
                }
            } else return null;
        }

        pub fn generateStates(self: Self, state: State, state_buf: *[4]State) []State {
            var idx: u8 = 0;
            if (state.pos.x > 0) {
                if (self.newStateIfValid(state, state.pos.x - 1, state.pos.y)) |s| {
                    state_buf[idx] = s;
                    idx += 1;
                }
            }
            if (state.pos.x < self.layout[0].len - 1) {
                if (self.newStateIfValid(state, state.pos.x + 1, state.pos.y)) |s| {
                    state_buf[idx] = s;
                    idx += 1;
                }
            }
            if (state.pos.y > 0) {
                if (self.newStateIfValid(state, state.pos.x, state.pos.y - 1)) |s| {
                    state_buf[idx] = s;
                    idx += 1;
                }
            }
            if (state.pos.y < self.layout.len - 1) {
                if (self.newStateIfValid(state, state.pos.x, state.pos.y + 1)) |s| {
                    state_buf[idx] = s;
                    idx += 1;
                }
            }
            return state_buf[0..idx];
        }

        fn newStateIfValid(self: Self, state: State, x: usize, y: usize) ?State {
            const tile = self.layout[y][x];
            if (tile == '#') {
                return null;
            }
            var visited = state.visited;
            if (tile >= '1' and tile <= '7') {
                visited |= std.math.shl(BitSetInt, 1, tile - 49);
            } else if (tile == '8' and visited == goal >> 1) {
                visited = goal;
            }
            return .{ .pos = .{ .x = x, .y = y }, .visited = visited };
        }

        fn cmp(_: void, a: struct { u16, State }, b: struct { u16, State }) std.math.Order {
            return std.math.order(a[0], b[0]);
        }
    };
}

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    var maze1, const start = try Maze(7).parse(tools.gpa, tools.input);
    defer maze1.deinit(tools.gpa);
    const p1 = try maze1.shortestPath(tools.gpa, start);

    var maze2: Maze(8) = .{ .layout = maze1.layout, .rowlist = maze1.rowlist };
    maze2.layout[start.y][start.x] = '8';

    return .{ p1, try maze2.shortestPath(tools.gpa, start) };
}

pub const solve = solver.intSolver(u16, solveInt);
