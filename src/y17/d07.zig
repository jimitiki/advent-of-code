const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

pub fn solve(tools: solver.Tools) solver.Error!solver.Result {
    const gpa = tools.gpa;
    var nodes: std.StringHashMapUnmanaged(void) = .empty;
    defer {
        var it = nodes.keyIterator();
        while (it.next()) |name| gpa.free(name.*);
        nodes.deinit(gpa);
    }
    var children: std.StringHashMapUnmanaged(void) = .empty;
    defer children.deinit(gpa);

    while (try tools.input.takeDelimiter('\n')) |line| {
        var parser: Parser = .init(line, .{});
        const name = try parser.take();
        if (!nodes.contains(name)) {
            const allocated = try gpa.alloc(u8, name.len);
            @memcpy(allocated, name);
            try nodes.put(gpa, allocated, {});
        }

        parser.skipMany(2) catch continue;
        while (true) {
            const child = parser.take() catch break;
            if (nodes.getKey(child)) |a| {
                try children.put(gpa, a, {});
            } else {
                const a = try gpa.alloc(u8, child.len);
                @memcpy(a, child);
                try nodes.put(gpa, a, {});
                try children.put(gpa, a, {});
            }
        }
    }
    var it = nodes.keyIterator();
    while (it.next()) |name| {
        if (!children.contains(name.*)) {
            @memcpy(tools.p1buf[0..name.len], name.*);
            return .{ tools.p1buf[0..name.len], null };
        }
    }
    return .{ null, null };
}
