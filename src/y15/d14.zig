const std = @import("std");

const solver = @import("../solver.zig");
const Counter = @import("../counter.zig").Counter(usize);
const Parser = @import("../Parser.zig");

// TODO: Create a visualization

const Reindeer = struct {
    speed: u32,
    duration: u32,
    rest: u32,

    fn distance(self: Reindeer, time: u32) u32 {
        const cycles = time / (self.duration + self.rest);
        const remainder = @min(self.duration, time % (self.duration + self.rest));
        const dist_per_cycle = self.speed * self.duration;
        return cycles * dist_per_cycle + remainder * self.speed;
    }
};

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var reindeer: std.ArrayList(Reindeer) = .empty;
    defer reindeer.deinit(tools.gpa);
    while (try tools.input.reader.takeDelimiter('\n')) |line| {
        var parser: Parser = .init(line, .{});
        try parser.skipMany(3);
        const speed = try parser.takeInt(u32);
        try parser.skipMany(2);
        const duration = try parser.takeInt(u32);
        try parser.skipMany(6);
        const rest = try parser.takeInt(u32);
        reindeer.append(tools.gpa, .{ .speed = speed, .duration = duration, .rest = rest }) catch unreachable;
    }

    const race_time = 2503;
    var scoreboard: Counter = .empty;
    defer scoreboard.deinit(tools.gpa);
    return .{
        maxDistance(reindeer.items, race_time),
        try maxPoints(tools.gpa, &scoreboard, reindeer.items, race_time),
    };
}

pub const solve = solver.intSolver(u32, solveInt);

fn maxDistance(reindeer: []Reindeer, time: u32) u32 {
    var max: u32 = 0;
    for (reindeer) |r| {
        max = @max(max, r.distance(time));
    }
    return max;
}

fn maxPoints(gpa: std.mem.Allocator, scoreboard: *Counter, reindeer: []Reindeer, time: u32) error{OutOfMemory}!u32 {
    for (1..time + 1) |t| {
        const max = maxDistance(reindeer, @truncate(t));
        for (reindeer, 0..) |r, i| {
            if (r.distance(@truncate(t)) == max) _ = try scoreboard.add(gpa, i);
        }
    }
    return @intCast(scoreboard.max()[1]);
}
