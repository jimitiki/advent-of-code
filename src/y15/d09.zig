const std = @import("std");
const NameSet = std.StringHashMapUnmanaged(void);
const EdgeMap = std.StringArrayHashMapUnmanaged(u16);
const Graph = std.StringArrayHashMapUnmanaged(EdgeMap);
const WordIterator = @import("../parse.zig").WordIterator;
const solver = @import("../solver.zig");
fn solveInt(gpa: std.mem.Allocator, input: *std.Io.Reader) solver.Error!struct { ?u32, ?u32 } {
    var graph: Graph = .empty;
    defer {
        var it = graph.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit(gpa);
        }
        graph.deinit(gpa);
    }
    var names: NameSet = .empty;
    defer {
        var it = names.keyIterator();
        while (it.next()) |name| {
            gpa.free(name.*);
        }
        names.deinit(gpa);
    }
    while (try input.takeDelimiter('\n')) |line| {
        const start, const end, const dist = try parseEdge(line);
        const start_name = getName(gpa, &names, start);
        const end_name = getName(gpa, &names, end);
        addEdge(gpa, &graph, start_name, end_name, dist);
        addEdge(gpa, &graph, end_name, start_name, dist);
    }
    const start = graph.keys()[0];
    const shortest_path: u32 = shortestPath(
        gpa,
        graph,
        std.math.maxInt(u32),
        .empty,
        start,
        0,
    );
    const longest_path: u32 = longestPath(
        gpa,
        graph,
        .empty,
        start,
        0,
    );
    return .{ shortest_path, longest_path };
}

pub const solve = solver.intSolver(u32, solveInt);

fn parseEdge(string: []const u8) error{InvalidInput}!struct { []const u8, []const u8, u16 } {
    var it: WordIterator = .init(string);
    const start = it.next() orelse return error.InvalidInput;
    _ = it.next() orelse return error.InvalidInput;
    const end = it.next() orelse return error.InvalidInput;
    _ = it.next() orelse return error.InvalidInput;
    const dist = it.next() orelse return error.InvalidInput;
    const distance = std.fmt.parseUnsigned(u16, dist, 10) catch return error.InvalidInput;
    return .{ start, end, distance };
}

fn getName(allocator: std.mem.Allocator, names: *NameSet, string: []const u8) []const u8 {
    if (names.getKey(string)) |name| {
        return name;
    } else {
        const name: []u8 = allocator.alloc(u8, string.len) catch unreachable;
        @memcpy(name, string);
        names.put(allocator, name, {}) catch unreachable;
        return name;
    }
}

fn addEdge(allocator: std.mem.Allocator, graph: *Graph, start: []const u8, end: []const u8, dist: u16) void {
    const result = graph.getOrPutValue(allocator, start, .empty) catch unreachable;
    result.value_ptr.putNoClobber(allocator, end, dist) catch unreachable;
}

fn shortestPath(
    allocator: std.mem.Allocator,
    graph: Graph,
    shortest_path: u32,
    visited: NameSet,
    current: []const u8,
    distance: u32,
) u32 {
    if (shortest_path <= distance) {
        return shortest_path;
    }
    if (visited.count() + 1 == graph.count()) {
        return distance;
    }

    var visited_new: NameSet = visited.clone(allocator) catch unreachable;
    defer visited_new.deinit(allocator);
    visited_new.put(allocator, current, {}) catch unreachable;

    const connections = graph.get(current).?;
    var it = connections.iterator();
    var new_shortest_path = shortest_path;
    while (it.next()) |entry| {
        if (visited.contains(entry.key_ptr.*)) {
            continue;
        }
        new_shortest_path = @min(new_shortest_path, shortestPath(
            allocator,
            graph,
            new_shortest_path,
            visited_new,
            entry.key_ptr.*,
            distance + entry.value_ptr.*,
        ));
    }
    return new_shortest_path;
}

fn longestPath(
    allocator: std.mem.Allocator,
    graph: Graph,
    visited: NameSet,
    current: []const u8,
    distance: u32,
) u32 {
    if (visited.count() + 1 == graph.count()) {
        return distance;
    }

    var visited_new: NameSet = visited.clone(allocator) catch unreachable;
    defer visited_new.deinit(allocator);
    visited_new.put(allocator, current, {}) catch unreachable;

    const connections = graph.get(current).?;
    var it = connections.iterator();
    var longest_path: u32 = 0;
    while (it.next()) |entry| {
        if (visited.contains(entry.key_ptr.*)) {
            continue;
        }
        longest_path = @max(longest_path, longestPath(
            allocator,
            graph,
            visited_new,
            entry.key_ptr.*,
            distance + entry.value_ptr.*,
        ));
    }
    return longest_path;
}
