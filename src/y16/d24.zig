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
        const PoiInt = std.math.Log2Int(BitSetInt);
        const wire_count = n;
        const goal = std.math.maxInt(BitSetInt);

        pub const State = struct {
            pos: Position,
            visited: BitSetInt = 0,

            pub fn finished(self: State) bool {
                return self.visited == goal;
            }
        };

        layout: []const []const ?PoiInt,
        rowlist: std.ArrayList([]const ?PoiInt),

        pub fn parse(gpa: std.mem.Allocator, reader: *std.Io.Reader) solver.Error!struct { Self, State } {
            const width = (reader.peekDelimiterExclusive('\n') catch return error.InvalidInput).len;
            var rows: std.ArrayList([]const ?PoiInt) = .empty;
            var start: State = undefined;
            var y: usize = 0;
            while (try reader.takeDelimiter('\n')) |line| : (y += 1) {
                if (line.len != width) return error.InvalidInput;
                var row = try gpa.alloc(?PoiInt, width);
                for (line, 0..) |char, x| {
                    switch (char) {
                        '1', '2', '3', '4', '5', '6', '7' => row[x] = @intCast(char - 48),
                        '0' => {
                            start = .{ .pos = .{ .x = x, .y = y } };
                            row[x] = 0;
                        },
                        '.' => row[x] = 0,
                        '#' => row[x] = null,
                        else => return error.InvalidInput,
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

        fn shortestPath(self: Self, gpa: std.mem.Allocator, start: State) error{OutOfMemory}!?u16 {
            var queue: std.PriorityQueue(struct { u16, State }, void, cmp) = .empty;
            defer queue.deinit(gpa);
            var minima: std.AutoHashMapUnmanaged(State, u16) = .empty;
            defer minima.deinit(gpa);
            var state_buf: [4]State = undefined;

            try queue.push(gpa, .{ 0, start });
            try minima.put(gpa, start, 0);

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
            const poi = self.layout[y][x] orelse return null;
            const visited = if (poi > 0) state.visited | @shlExact(@as(BitSetInt, 1), poi - 1) else state.visited;
            return .{ .pos = .{ .x = x, .y = y }, .visited = visited };
        }

        fn cmp(_: void, a: struct { u16, State }, b: struct { u16, State }) std.math.Order {
            return std.math.order(a[0], b[0]);
        }
    };
}

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    var maze, const start = try Maze(7).parse(tools.gpa, tools.input);
    defer maze.deinit(tools.gpa);
    return .{ try maze.shortestPath(tools.gpa, start), null };
}

pub const solve = solver.intSolver(u16, solveInt);
