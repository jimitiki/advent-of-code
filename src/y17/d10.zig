const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

const KnotHasher = @import("KnotHasher.zig");

pub fn solve(tools: solver.Tools) solver.Error!solver.Result {
    const input = try tools.input.takeDelimiter('\n') orelse return error.InvalidInput;
    var count: usize = 1;
    for (input) |char| {
        if (char == ',') count += 1;
    }
    const lengths = try tools.gpa.alloc(usize, count);
    defer tools.gpa.free(lengths);
    var parser: Parser = .init(input, .{});
    for (0..lengths.len) |i| {
        lengths[i] = try parser.takeInt(usize);
    }

    var hasher: KnotHasher = .init();
    for (lengths) |length| hasher.reverse(length);
    const p1_str = std.fmt.bufPrint(
        tools.p1buf,
        "{}",
        .{@as(u16, hasher.buf[0]) * hasher.buf[1]},
    ) catch unreachable;

    hasher = .init();
    hasher.hash(input, tools.p2buf);

    return .{ p1_str, tools.p2buf };
}
