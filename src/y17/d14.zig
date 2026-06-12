const std = @import("std");

const solver = @import("../solver.zig");
const t = @import("../test.zig");
const KnotHasher = @import("KnotHasher.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    const key = try tools.input.takeDelimiter('\n') orelse return error.InvalidInput;
    var message = try tools.gpa.alloc(u8, key.len + 4);
    defer tools.gpa.free(message);

    @memcpy(message[0..key.len], key);
    message[key.len] = '-';

    var digest: [16]u8 = undefined;
    var count_used: u16 = 0;
    for (0..128) |row_index| {
        const suffix = std.fmt.bufPrint(message[key.len + 1 ..], "{}", .{row_index}) catch unreachable;
        var hasher: KnotHasher = .init();
        hasher.hash(message[0 .. key.len + 1 + suffix.len], &digest);
        for (digest) |byte| {
            count_used += @popCount(byte);
        }
    }
    return .{ count_used, null };
}

pub const solve = solver.intSolver(u16, solveInt);

test "solve" {
    try t.expectIntSolution(u16, solveInt, .{ 8108, null }, "flqrgnkx");
}
