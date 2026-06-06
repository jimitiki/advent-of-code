const std = @import("std");
const Allocator = std.mem.Allocator;

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

const State = struct {
    ev: u2,
    devs: []const u2,
    cidx: usize,
    hash: u64,

    const SortContext = struct {
        rtgs: []u2,
        chips: []u2,

        pub fn swap(self: @This(), a: usize, b: usize) void {
            std.mem.swap(u2, &self.chips[a], &self.chips[b]);
            std.mem.swap(u2, &self.rtgs[a], &self.rtgs[b]);
        }

        pub fn lessThan(self: @This(), a: usize, b: usize) bool {
            return self.chips[a] < self.chips[b] or self.chips[a] == self.chips[b] and self.rtgs[a] < self.rtgs[b];
        }
    };

    pub fn init(ev: u2, devs: []u2) State {
        const cidx = @divExact(devs.len, 2);
        std.sort.pdqContext(0, cidx, State.SortContext{ .rtgs = devs[0..cidx], .chips = devs[cidx..] });
        return .{
            .ev = ev,
            .devs = devs,
            .cidx = cidx,
            .hash = std.hash.Wyhash.hash(ev, @ptrCast(devs)),
        };
    }

    pub fn valid(self: State) bool {
        for (self.devs[0..self.cidx], 0..) |floor, i| {
            if (floor == self.devs[i + self.cidx]) continue;
            for (self.devs[self.cidx..]) |f| {
                if (floor == f) return false;
            }
        }
        return true;
    }

    pub fn finished(self: State) bool {
        for (self.devs) |floor| if (floor != 3) return false;
        return true;
    }
};

fn compare(_: void, lhs: struct { State, u32 }, rhs: struct { State, u32 }) std.math.Order {
    return std.math.order(lhs[1], rhs[1]);
}
const Queue = std.PriorityQueue(struct { State, u32 }, void, compare);
const Context = struct {
    pub fn hash(_: @This(), state: State) u64 {
        return state.hash;
    }

    pub fn eql(_: @This(), a: State, b: State) bool {
        return a.ev == b.ev and std.mem.eql(u2, a.devs, b.devs);
    }
};
fn StateMap(comptime V: type) type {
    return std.HashMapUnmanaged(State, V, Context, 80);
}

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    const gpa = tools.gpa;
    var chips: std.StringHashMapUnmanaged(u2) = .empty;
    defer chips.deinit(gpa);
    var rtgs: std.StringHashMapUnmanaged(u2) = .empty;
    defer rtgs.deinit(gpa);

    var i: u2 = 0;
    while (try tools.input.takeDelimiter('\n')) |line| : (i += 1) {
        var parser: Parser = .init(line, .{});
        try parser.skipMany(4);
        while (try parseElement(&parser)) |result| {
            if (result[1]) {
                try chips.put(gpa, result[0], i);
            } else {
                try rtgs.put(gpa, result[0], i);
            }
        }
        if (i == 3) break;
    }
    const devices_p1 = try gpa.alloc(u2, chips.size * 2);
    defer gpa.free(devices_p1);
    @memset(devices_p1, 0);
    var it = chips.iterator();
    var idx: usize = 0;
    while (it.next()) |entry| : (idx += 1) {
        devices_p1[idx] = entry.value_ptr.*;
        devices_p1[idx + chips.size] = rtgs.get(entry.key_ptr.*).?;
    }
    const state_p1: State = .init(0, devices_p1);

    const devices_p2 = try gpa.alloc(u2, devices_p1.len + 4);
    defer gpa.free(devices_p2);
    @memset(devices_p2, 0);
    @memcpy(devices_p2[0..state_p1.cidx], devices_p1[0..state_p1.cidx]);
    @memcpy(devices_p2[state_p1.cidx + 2 .. devices_p2.len - 2], devices_p1[state_p1.cidx..]);
    const state_p2: State = .init(0, devices_p2);

    return .{ try minSteps(gpa, state_p1), try minSteps(gpa, state_p2) };
}

fn parseElement(parser: *Parser) Parser.Error!?struct { []const u8, bool } {
    const hint = parser.take() catch return null;
    if (std.mem.eql(u8, "nothing", hint)) return null;
    if (std.mem.eql(u8, "and", hint)) try parser.skip();
    const element = try parser.take();
    try parser.skip();
    if (element.len > 11 and std.mem.eql(u8, "-compatible", element[element.len - 11 ..])) {
        return .{ element[0 .. element.len - 11], true };
    } else {
        return .{ element, false };
    }
}

pub const solve = solver.intSolver(u32, solveInt);

fn minSteps(gpa: Allocator, start: State) error{OutOfMemory}!?u32 {
    var predecessors: StateMap(State) = .empty;
    defer {
        var it = predecessors.keyIterator();
        while (it.next()) |s| gpa.free(s.devs);
        predecessors.deinit(gpa);
    }
    var queue: Queue = .empty;
    defer queue.deinit(gpa);
    var minima: StateMap(u32) = .empty;
    defer minima.deinit(gpa);
    const dev_buf = try gpa.alloc(u2, start.devs.len);
    defer gpa.free(dev_buf);

    try queue.push(gpa, .{ start, 0 });
    while (queue.pop()) |entry| {
        const state, const dist = entry;
        if (state.finished()) {
            return dist;
        }
        const new_dist = dist + 1;
        for ([_]bool{ true, false }) |up| {
            if (up and state.ev == 3) continue;
            if (!up and state.ev == 0) continue;

            const new_floor = if (up) state.ev + 1 else state.ev - 1;
            for (state.devs, 0..) |a, i| {
                if (a != state.ev) continue;
                for (state.devs[i..], i..) |b, j| {
                    if (b != state.ev) continue;

                    @memcpy(dev_buf, state.devs);
                    dev_buf[i] = new_floor;
                    if (i != j) dev_buf[j] = new_floor;
                    const candidate: State = .init(new_floor, dev_buf);
                    if (!candidate.valid()) continue;
                    const allocated = predecessors.getKey(candidate) orelse try cloneState(gpa, candidate);
                    if (new_dist < minima.get(allocated) orelse std.math.maxInt(u32)) {
                        try predecessors.put(gpa, allocated, state);
                        try minima.put(gpa, allocated, new_dist);
                        try queue.push(gpa, .{ allocated, new_dist });
                    }
                }
            }
        }
    } else return null;
}

fn cloneState(gpa: Allocator, original: State) error{OutOfMemory}!State {
    const devices = try gpa.alloc(u2, original.devs.len);
    @memcpy(devices, original.devs);
    return .{ .ev = original.ev, .devs = devices, .cidx = original.cidx, .hash = original.hash };
}
