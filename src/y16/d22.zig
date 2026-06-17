const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

// TODO: Speed this up, possibly by using A*
// TODO: Create a visualization of the path

const Node = struct {
    size: u16,
    used: u16,
    avail: u16,
};
const State = packed struct(u32) {
    empty_idx: u16,
    data_idx: u16,
};
fn StateMap(comptime V: type) type {
    return std.AutoHashMapUnmanaged(State, V);
}
fn lessThan(_: void, a: struct { u16, State }, b: struct { u16, State }) std.math.Order {
    return std.math.order(a[0], b[0]);
}
const Queue = std.PriorityQueue(struct { u16, State }, void, lessThan);

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    var nodes: std.ArrayList(Node) = .empty;
    defer nodes.deinit(tools.gpa);

    var reader = input.reader();
    _ = reader.discardDelimiterInclusive('\n') catch return error.InvalidInput;
    _ = reader.discardDelimiterInclusive('\n') catch return error.InvalidInput;
    var height: u16 = 0;
    var line_no: u16 = 0;
    while (try reader.takeDelimiter('\n')) |line| : (line_no += 1) {
        if (height == 0 and line[16] == '1') height = line_no;
        try nodes.append(tools.gpa, try parseNode(line));
    }

    var valid_pairs: u16 = 0;
    var ao: u16 = 0;
    for (nodes.items, 0..) |a, i| {
        for (nodes.items[i..]) |b| {
            if (isValidPair(a, b)) {
                valid_pairs += 1;
                ao += 1;
            }
            if (isValidPair(b, a)) valid_pairs += 1;
        }
    }
    return .{ valid_pairs, try shortestPath(tools.gpa, nodes.items, height) };
}

pub const solve = solver.intSolver(u16, solveInt);

fn parseNode(str: []const u8) Parser.Error!Node {
    var parser: Parser = .init(str, .{});
    try parser.skip();
    const size = try parser.take();
    const used = try parser.take();
    const avail = try parser.take();
    return .{
        .size = std.fmt.parseUnsigned(u16, size[0 .. size.len - 1], 10) catch return error.InvalidToken,
        .used = std.fmt.parseUnsigned(u16, used[0 .. used.len - 1], 10) catch return error.InvalidToken,
        .avail = std.fmt.parseUnsigned(u16, avail[0 .. avail.len - 1], 10) catch return error.InvalidToken,
    };
}

fn isValidPair(a: Node, b: Node) bool {
    return a.used > 0 and a.used <= b.avail;
}

fn shortestPath(gpa: std.mem.Allocator, nodes: []const Node, height: u16) error{OutOfMemory}!?u16 {
    var queue: Queue = .empty;
    defer queue.deinit(gpa);
    var minima: StateMap(u16) = .empty;
    defer minima.deinit(gpa);
    var state_buf: [4]State = undefined;

    const start = initialState(nodes, height) orelse return null;
    try minima.put(gpa, start, 0);
    try queue.push(gpa, .{ 0, start });

    while (queue.pop()) |entry| {
        const dist, const state = entry;
        if (state.data_idx == 0) {
            return dist;
        }
        const new_dist = dist + 1;
        for (generateStates(nodes, &state_buf, height, state)) |next| {
            if (new_dist >= minima.get(next) orelse std.math.maxInt(u16)) continue;
            try minima.put(gpa, next, new_dist);
            try queue.push(gpa, .{ new_dist, next });
        }
    }
    return null;
}

fn generateStates(nodes: []const Node, state_buf: *[4]State, height: u16, state: State) []const State {
    var state_cnt: u8 = 0;
    if (state.empty_idx >= height) {
        if (newStateIfValid(nodes, state, state.empty_idx - height)) |s| {
            state_buf[state_cnt] = s;
            state_cnt += 1;
        }
    }
    if (state.empty_idx < @as(u16, @intCast(nodes.len)) - height) {
        if (newStateIfValid(nodes, state, state.empty_idx + height)) |s| {
            state_buf[state_cnt] = s;
            state_cnt += 1;
        }
    }
    if (state.empty_idx % height > 0) {
        if (newStateIfValid(nodes, state, state.empty_idx - 1)) |s| {
            state_buf[state_cnt] = s;
            state_cnt += 1;
        }
    }
    if (state.empty_idx % height < height - 1) {
        if (newStateIfValid(nodes, state, state.empty_idx + 1)) |s| {
            state_buf[state_cnt] = s;
            state_cnt += 1;
        }
    }
    return state_buf[0..state_cnt];
}

fn newStateIfValid(nodes: []const Node, state: State, new_empty_idx: u16) ?State {
    if (nodes[new_empty_idx].used > nodes[state.empty_idx].size) return null;
    const new_data_idx = if (state.data_idx == new_empty_idx) state.empty_idx else state.data_idx;
    return .{ .empty_idx = new_empty_idx, .data_idx = new_data_idx };
}

fn initialState(nodes: []const Node, height: u16) ?State {
    const data_idx: u16 = @as(u16, @intCast(nodes.len)) - height;
    for (nodes, 0..) |node, i| {
        if (node.used == 0) return .{ .empty_idx = @intCast(i), .data_idx = data_idx };
    } else return null;
}
