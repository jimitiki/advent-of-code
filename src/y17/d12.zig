const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

const Group = std.AutoHashMapUnmanaged(u16, void);

// TODO: Improve the efficiency of the algorithm

fn solveInt(tools: solver.Tools) solver.Error!struct { ?usize, ?usize } {
    const gpa = tools.gpa;
    var link_list: std.ArrayList(struct { u16, u16 }) = .empty;
    defer link_list.deinit(gpa);

    while (try tools.input.takeDelimiter('\n')) |line| {
        var parser: Parser = .init(line, .{});
        const pid = try parser.takeInt(u16);
        try parser.skip();
        while (true) {
            try link_list.append(gpa, .{ pid, parser.takeInt(u16) catch break });
        }
    }

    var group_list: std.ArrayList(Group) = .empty;
    defer {
        for (group_list.items) |*group| group.deinit(gpa);
        group_list.deinit(gpa);
    }
    for (link_list.items) |link| {
        for (group_list.items) |*group| {
            if (group.contains(link[0])) {
                break;
            }
        } else {
            var group: Group = .empty;
            try group.put(gpa, link[0], {});
            try connect(gpa, link_list.items, &group, link[0]);
            try group_list.append(gpa, group);
        }
    }
    return .{ group_list.items[0].size, group_list.items.len };
}

pub const solve = solver.intSolver(usize, solveInt);

fn connect(gpa: std.mem.Allocator, links: []const struct { u16, u16 }, group: *Group, pid: u16) error{OutOfMemory}!void {
    for (links) |link| {
        const other = if (link[0] == pid) link[1] else if (link[1] == pid) link[0] else continue;
        const result = try group.getOrPut(gpa, other);
        if (!result.found_existing) {
            try connect(gpa, links, group, other);
        }
    }
}
