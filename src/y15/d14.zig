const std = @import("std");

const solver = @import("../solver.zig");
const Counter = @import("../counter.zig").Counter(usize);
const WordIterator = @import("../parse.zig").WordIterator;

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
    while (try tools.input.takeDelimiter('\n')) |line| {
        var it: WordIterator = .init(line);
        for (0..3) |_| {
            _ = it.next();
        }
        const speed = std.fmt.parseUnsigned(u32, it.next().?, 10) catch return error.InvalidInput;
        for (0..2) |_| {
            _ = it.next();
        }
        const duration = std.fmt.parseUnsigned(u32, it.next().?, 10) catch return error.InvalidInput;
        for (0..6) |_| {
            _ = it.next();
        }
        const rest = std.fmt.parseUnsigned(u32, it.next().?, 10) catch return error.InvalidInput;
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
