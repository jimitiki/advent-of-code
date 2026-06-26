const std = @import("std");
const lib = @import("lib");

const solver = lib.solver;
const testing = lib.testing;

const LinkedRing = lib.LinkedRing;

const Entry = struct {
    score: u32,
    node: LinkedRing.Node = .{},
};

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var parser = input.parser(.{});
    const player_count = try parser.takeInt(u32);
    try parser.skipMany(5);
    const marble_count = (try parser.takeInt(u32) + 1);

    return .{
        try highScore(tools.gpa, player_count, marble_count),
        try highScore(tools.gpa, player_count, marble_count * 100),
    };
}

pub const solve = solver.intSolver(u32, solveInt);

fn highScore(gpa: std.mem.Allocator, player_count: u32, marble_count: u32) error{OutOfMemory}!u32 {
    var buf = try gpa.alloc(Entry, marble_count);
    defer gpa.free(buf);
    var scores: std.AutoHashMapUnmanaged(u32, u32) = .empty;
    defer scores.deinit(gpa);

    try scores.ensureTotalCapacity(gpa, player_count);
    for (0..player_count) |i| scores.putAssumeCapacity(@intCast(i), 0);
    buf[0] = .{ .score = 0 };
    var marble = &buf[0];
    var marbles: LinkedRing = .init(&marble.node);

    var player: u32 = 1;
    var index: usize = 1;
    for (1..marble_count) |m| {
        if (m % 23 == 0) {
            var node = &marble.node;
            for (0..7) |_| node = node.prev;
            marble = @fieldParentPtr("node", node);

            const score: u32 = @intCast(m + marble.score);
            scores.getEntry(player).?.value_ptr.* += score;

            marbles.remove(&marble.node);
            marble = @fieldParentPtr("node", marble.node.next);
        } else {
            buf[index] = .{ .score = @intCast(m) };
            marbles.insertAfter(marble.node.next, &buf[index].node);
            marble = &buf[index];
            index += 1;
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
    try std.testing.expectEqual(32, try highScore(std.testing.allocator, 5, 26));
    try std.testing.expectEqual(8317, try highScore(std.testing.allocator, 10, 1619));
}
