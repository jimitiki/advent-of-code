const std = @import("std");

const NameSet = std.StringHashMapUnmanaged(void);
const EdgeMap = std.StringArrayHashMapUnmanaged(u16);
const Graph = std.StringArrayHashMapUnmanaged(EdgeMap);

const lib = @import("lib");
const Boilerplate = lib.Boilerplate;
const WordIterator = lib.parse.WordIterator;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;

    var graph: Graph = .empty;
    defer graph.deinit(bp.arena);
    var names: NameSet = .empty;
    defer {
        var it = names.keyIterator();
        while (it.next()) |name| {
            bp.arena.free(name.*);
        }
        names.deinit(bp.arena);
    }
    while (try input.takeDelimiter('\n')) |line| {
        const start, const end, const dist = try parseEdge(line);
        const start_name = try getName(bp.arena, &names, start);
        const end_name = try getName(bp.arena, &names, end);
        try addEdge(bp.arena, &graph, start_name, end_name, dist);
        try addEdge(bp.arena, &graph, end_name, start_name, dist);
    }
    var it = graph.iterator();
    if (bp.part == .p1) {
        var shortest_path: u64 = std.math.maxInt(u64);
        while (it.next()) |entry| {
            shortest_path = @min(shortest_path, try shortestPath(
                bp.arena,
                graph,
                shortest_path,
                .empty,
                entry.key_ptr.*,
                0,
            ));
        }
        try stdout.print("{}\n", .{shortest_path});
    } else {
        var longest_path: u64 = 0;
        while (it.next()) |entry| {
            longest_path = @max(longest_path, try longestPath(
                bp.arena,
                graph,
                .empty,
                entry.key_ptr.*,
                0,
            ));
        }
        try stdout.print("{}\n", .{longest_path});
    }

    try stdout.flush();
}

fn parseEdge(string: []const u8) !struct { []const u8, []const u8, u16 } {
    var it: WordIterator = .init(string);
    const start = it.next().?;
    _ = it.next().?;
    const end = it.next().?;
    _ = it.next().?;
    const dist = it.next().?;
    return .{ start, end, try std.fmt.parseUnsigned(u16, dist, 10) };
}

fn getName(allocator: std.mem.Allocator, names: *NameSet, string: []const u8) ![]const u8 {
    if (names.getKey(string)) |name| {
        return name;
    } else {
        const name: []u8 = try allocator.alloc(u8, string.len);
        @memcpy(name, string);
        try names.put(allocator, name, {});
        return name;
    }
}

fn addEdge(allocator: std.mem.Allocator, graph: *Graph, start: []const u8, end: []const u8, dist: u16) !void {
    const result = try graph.getOrPutValue(allocator, start, .empty);
    try result.value_ptr.putNoClobber(allocator, end, dist);
}

fn shortestPath(
    allocator: std.mem.Allocator,
    graph: Graph,
    shortest_path: u64,
    visited: NameSet,
    current: []const u8,
    distance: u64,
) !u64 {
    if (shortest_path <= distance) {
        return shortest_path;
    }
    if (visited.count() + 1 == graph.count()) {
        return distance;
    }

    var visited_new: NameSet = try visited.clone(allocator);
    defer visited_new.deinit(allocator);
    try visited_new.put(allocator, current, {});

    const connections = graph.get(current).?;
    var it = connections.iterator();
    var new_shortest_path = shortest_path;
    while (it.next()) |entry| {
        if (visited.contains(entry.key_ptr.*)) {
            continue;
        }
        new_shortest_path = @min(new_shortest_path, try shortestPath(
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
    distance: u64,
) !u64 {
    if (visited.count() + 1 == graph.count()) {
        return distance;
    }

    var visited_new: NameSet = try visited.clone(allocator);
    defer visited_new.deinit(allocator);
    try visited_new.put(allocator, current, {});

    const connections = graph.get(current).?;
    var it = connections.iterator();
    var longest_path: u64 = 0;
    while (it.next()) |entry| {
        if (visited.contains(entry.key_ptr.*)) {
            continue;
        }
        longest_path = @max(longest_path, try longestPath(
            allocator,
            graph,
            visited_new,
            entry.key_ptr.*,
            distance + entry.value_ptr.*,
        ));
    }
    return longest_path;
}
