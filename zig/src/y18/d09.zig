const std = @import("std");

const solver = @import("../solver.zig");
const testing = @import("../testing.zig");

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var parser = input.parser(.{});
    const player_count = try parser.takeInt(u32);
    try parser.skipMany(5);
    const marble_count = try parser.takeInt(u32);

    return .{
        try highScore(tools.gpa, player_count, marble_count),
        try highScore(tools.gpa, player_count, marble_count * 100),
    };
}

pub const solve = solver.intSolver(u32, solveInt);

fn highScore(gpa: std.mem.Allocator, player_count: u32, marble_count: u32) error{OutOfMemory}!u32 {
    var marbles: std.ArrayList(u32) = .empty;
    defer marbles.deinit(gpa);
    var scores: std.AutoHashMapUnmanaged(u32, u32) = .empty;
    defer scores.deinit(gpa);

    try marbles.ensureTotalCapacity(gpa, marble_count - (marble_count / 23));
    marbles.appendAssumeCapacity(0);
    try scores.ensureTotalCapacity(gpa, player_count);
    for (0..player_count) |i| scores.putAssumeCapacity(@intCast(i), 0);

    var player: u32 = 1;
    var index: usize = 1;
    for (1..marble_count + 1) |i| {
        const marble: u32 = @intCast(i);
        if (marble % 23 == 0) {
            index = (index + marbles.items.len - 7) % marbles.items.len;
            const score = marble + marbles.orderedRemove(index);
            scores.getEntry(player).?.value_ptr.* += score;
        } else {
            index = (index + 2) % marbles.items.len;
            marbles.insertAssumeCapacity(index, marble);
        }
        player = (player + 1) % player_count;
    }
    var max: u32 = 0;
    var it = scores.iterator();
    while (it.next()) |entry| {
        max = @max(max, entry.value_ptr.*);
    }
    return max;
}

test "high score" {
    try std.testing.expectEqual(32, (try highScore(std.testing.allocator, 5, 25))[0]);
    try std.testing.expectEqual(8317, (try highScore(std.testing.allocator, 10, 1618))[0]);
}
