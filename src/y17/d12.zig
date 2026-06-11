const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

const Group = std.AutoHashMapUnmanaged(u16, void);

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
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

    var group: Group = .empty;
    defer group.deinit(gpa);
    var queue: std.Deque(u16) = .empty;
    defer queue.deinit(gpa);

    try group.put(gpa, 0, {});
    try queue.pushBack(gpa, 0);
    while (queue.popFront()) |pid| {
        for (link_list.items) |link| {
            const other = if (pid == link[0]) link[1] else if (pid == link[1]) link[0] else continue;
            const result = try group.getOrPut(gpa, other);
            if (!result.found_existing) {
                try queue.pushBack(gpa, other);
            }
        }
    }
    return .{ group.size, null };
}

pub const solve = solver.intSolver(u32, solveInt);
