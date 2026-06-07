const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

const Node = struct {
    used: u16,
    avail: u16,
};

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    var nodes: std.ArrayList(Node) = .empty;
    defer nodes.deinit(tools.gpa);

    const input = tools.input;
    _ = input.discardDelimiterInclusive('\n') catch return error.InvalidInput;
    _ = input.discardDelimiterInclusive('\n') catch return error.InvalidInput;
    while (try input.takeDelimiter('\n')) |line| {
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
    return .{ valid_pairs, null };
}

pub const solve = solver.intSolver(u16, solveInt);

fn parseNode(str: []const u8) Parser.Error!Node {
    var parser: Parser = .init(str, .{});
    try parser.skipMany(2);
    const used = try parser.take();
    const avail = try parser.take();
    return .{
        .used = std.fmt.parseUnsigned(u16, used[0 .. used.len - 1], 10) catch return error.InvalidToken,
        .avail = std.fmt.parseUnsigned(u16, avail[0 .. avail.len - 1], 10) catch return error.InvalidToken,
    };
}

fn isValidPair(a: Node, b: Node) bool {
    return a.used > 0 and a.used <= b.avail;
}
