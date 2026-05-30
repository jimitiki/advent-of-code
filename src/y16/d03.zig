const std = @import("std");

const solver = @import("../solver.zig");
const WordIterator = @import("../parse.zig").WordIterator;

fn solveInt(_: std.mem.Allocator, input: *std.Io.Reader) solver.Error!struct { ?u32, ?u32 } {
    var count: u32 = 0;
    while (try input.takeDelimiter('\n')) |line| {
        const l1, const l2, const l3 = try parseTriangle(line);
        if (l1 + l2 > l3 and l1 + l3 > l2 and l2 + l3 > l1) {
            count += 1;
        }
    }
    return .{ count, null };
}

pub const solve = solver.intSolver(u32, solveInt);

fn parseTriangle(str: []const u8) error{InvalidInput}!struct { u32, u32, u32 } {
    var it = WordIterator.init(str);
    const l1 = try parseLength(&it);
    const l2 = try parseLength(&it);
    const l3 = try parseLength(&it);
    return .{ l1, l2, l3 };
}

fn parseLength(it: *WordIterator) error{InvalidInput}!u32 {
    const word = it.next() orelse return error.InvalidInput;
    return std.fmt.parseUnsigned(u32, word, 10) catch error.InvalidInput;
}
