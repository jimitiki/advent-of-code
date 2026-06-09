const std = @import("std");
const NameTable = std.StringHashMapUnmanaged(usize);
const NodeSet = std.AutoHashMapUnmanaged(usize, void);
const Parser = @import("../Parser.zig");
const solver = @import("../solver.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    const gpa = tools.gpa;
    const graph = try constructGraph(gpa, tools.input);
    defer {
        for (graph) |node_edges| {
            gpa.free(node_edges);
        }
        gpa.free(graph);
    }

    var visited: NodeSet = .empty;
    defer visited.deinit(gpa);
    try visited.ensureTotalCapacity(gpa, @intCast(graph.len));

    const shortest_path: u16 = shortestPath(graph, std.math.maxInt(u16), &visited, 0, 0);
    const longest_path: u16 = longestPath(graph, &visited, 0, 0);
    return .{ shortest_path, longest_path };
}

pub const solve = solver.intSolver(u16, solveInt);

fn constructGraph(gpa: std.mem.Allocator, input: *std.Io.Reader) solver.Error![]const []const u16 {
    var names: NameTable = .empty;
    defer {
        var it = names.keyIterator();
        while (it.next()) |name| {
            gpa.free(name.*);
        }
        names.deinit(gpa);
    }

    var edges: std.ArrayList(struct { usize, usize, u16 }) = .empty;
    defer edges.deinit(gpa);
    while (try input.takeDelimiter('\n')) |line| {
        const src, const dest, const dist = try parseEdge(line);
        const src_idx = getIndex(gpa, &names, src);
        const dest_idx = getIndex(gpa, &names, dest);
        try edges.append(gpa, .{ src_idx, dest_idx, dist });
    }

    var graph = try gpa.alloc([]u16, names.size);
    for (0..names.size) |i| {
        graph[i] = try gpa.alloc(u16, names.size);
        graph[i][i] = 0;
    }
    for (edges.items) |edge| {
        graph[edge[0]][edge[1]] = edge[2];
        graph[edge[1]][edge[0]] = edge[2];
    }
    return graph;
}

fn parseEdge(string: []const u8) Parser.Error!struct { []const u8, []const u8, u16 } {
    var parser: Parser = .init(string, .{});
    const start = try parser.take();
    try parser.skip();
    const end = try parser.take();
    try parser.skip();
    const distance = try parser.takeInt(u16);
    return .{ start, end, distance };
}

fn getIndex(allocator: std.mem.Allocator, names: *NameTable, string: []const u8) usize {
    if (names.get(string)) |index| {
        return index;
    } else {
        const name: []u8 = allocator.alloc(u8, string.len) catch unreachable;
        @memcpy(name, string);
        names.put(allocator, name, names.size) catch unreachable;
        return names.size - 1;
    }
}

fn shortestPath(
    graph: []const []const u16,
    shortest_path: u16,
    visited: *NodeSet,
    current: usize,
    distance: u16,
) u16 {
    if (shortest_path <= distance) return shortest_path;
    if (visited.count() == graph.len) return distance;

    var new_shortest_path = shortest_path;
    for (graph[current], 0..) |inc_dist, next| {
        if (visited.contains(next)) continue;
        visited.putAssumeCapacity(next, {});
        defer _ = visited.remove(next);
        new_shortest_path = @min(new_shortest_path, shortestPath(graph, new_shortest_path, visited, next, distance + inc_dist));
    }
    return new_shortest_path;
}

fn longestPath(
    graph: []const []const u16,
    visited: *NodeSet,
    current: usize,
    distance: u16,
) u16 {
    if (visited.count() == graph.len) return distance;

    var longest_path: u16 = 0;
    for (graph[current], 0..) |inc_dist, next| {
        if (visited.contains(next)) continue;
        visited.putAssumeCapacity(next, {});
        defer _ = visited.remove(next);
        longest_path = @max(longest_path, longestPath(graph, visited, next, distance + inc_dist));
    }
    return longest_path;
}
