const std = @import("std");

const solver = @import("../solver.zig");
const WordIterator = @import("../parse.zig").WordIterator;

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var t1 = [_]u32{ 0, 0, 0 };
    var t2 = [_]u32{ 0, 0, 0 };
    var t3 = [_]u32{ 0, 0, 0 };
    var count_h: u32 = 0;
    var count_v: u32 = 0;
    var i: u2 = 0;
    while (try tools.input.takeDelimiter('\n')) |line| : (i = (i + 1) % 3) {
        const triangle = try parseTriangle(line);
        if (validateTriangle(triangle)) {
            count_h += 1;
        }

        t1[i] = triangle[0];
        t2[i] = triangle[1];
        t3[i] = triangle[2];
        if (i == 2) {
            if (validateTriangle(t1)) count_v += 1;
            if (validateTriangle(t2)) count_v += 1;
            if (validateTriangle(t3)) count_v += 1;
        }
    }
    return .{ count_h, count_v };
}

pub const solve = solver.intSolver(u32, solveInt);

fn validateTriangle(edges: [3]u32) bool {
    return edges[0] + edges[1] > edges[2] and edges[1] + edges[2] > edges[0] and edges[0] + edges[2] > edges[1];
}

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
