const std = @import("std");

const solver = @import("../solver.zig");
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

const Counter = struct {
    backing: Backing,

    const Self = @This();
    const Backing = std.AutoHashMapUnmanaged(usize, u32);

    pub fn init(allocator: std.mem.Allocator, reindeer: []const Reindeer) Self {
        var backing: Backing = .empty;
        for (reindeer, 0..) |_, i| {
            backing.put(allocator, i, 0) catch unreachable;
        }
        return .{ .backing = backing };
    }

    pub fn add(self: *Self, item: usize) void {
        const count = self.backing.getPtr(item).?;
        count.* += 1;
    }

    pub fn max(self: Self) u32 {
        var m: u32 = 0;
        var it = self.backing.valueIterator();
        while (it.next()) |count| {
            m = @max(m, count.*);
        }
        return m;
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        self.backing.deinit(allocator);
    }
};

fn solveInt(gpa: std.mem.Allocator, input: *std.Io.Reader) solver.Error!struct { ?u32, ?u32 } {
    var reindeer: std.ArrayList(Reindeer) = .empty;
    defer reindeer.deinit(gpa);
    while (try input.takeDelimiter('\n')) |line| {
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
        reindeer.append(gpa, .{ .speed = speed, .duration = duration, .rest = rest }) catch unreachable;
    }

    const race_time = 2503;
    var scoreboard: Counter = .init(gpa, reindeer.items);
    defer scoreboard.deinit(gpa);
    return .{ maxDistance(reindeer.items, race_time), maxPoints(&scoreboard, reindeer.items, race_time) };
}

pub const solve = solver.intSolver(u32, solveInt);

fn maxDistance(reindeer: []Reindeer, time: u32) u32 {
    var max: u32 = 0;
    for (reindeer) |r| {
        max = @max(max, r.distance(time));
    }
    return max;
}

fn maxPoints(scoreboard: *Counter, reindeer: []Reindeer, time: u32) u32 {
    for (1..time + 1) |t| {
        const max = maxDistance(reindeer, @truncate(t));
        for (reindeer, 0..) |r, i| {
            if (r.distance(@truncate(t)) == max) scoreboard.add(i);
        }
    }
    return scoreboard.max();
}
