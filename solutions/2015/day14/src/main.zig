const std = @import("std");

const lib = @import("lib");
const Boilerplate = lib.Boilerplate;

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

    pub fn init(allocator: std.mem.Allocator, reindeer: []const Reindeer) std.mem.Allocator.Error!Self {
        var backing: Backing = .empty;
        for (reindeer, 0..) |_, i| {
            try backing.put(allocator, i, 0);
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

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        self.backing.deinit(allocator);
    }
};

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;
    var reindeer: std.ArrayList(Reindeer) = .empty;
    defer reindeer.deinit(bp.arena);
    while (try input.takeDelimiter('\n')) |line| {
        var it = lib.parse.WordIterator.init(line);
        for (0..3) |_| {
            _ = it.next();
        }
        const speed = try std.fmt.parseUnsigned(u32, it.next().?, 10);
        for (0..2) |_| {
            _ = it.next();
        }
        const duration = try std.fmt.parseUnsigned(u32, it.next().?, 10);
        for (0..6) |_| {
            _ = it.next();
        }
        const rest = try std.fmt.parseUnsigned(u32, it.next().?, 10);
        try reindeer.append(bp.arena, .{ .speed = speed, .duration = duration, .rest = rest });
    }

    const time = try std.fmt.parseUnsigned(u32, bp.args[4], 10);
    if (bp.part == .p1) {
        try stdout.print("{}\n", .{maxDistance(reindeer.items, time)});
    } else {
        var scoreboard: Counter = try .init(bp.arena, reindeer.items);
        try stdout.print("{}\n", .{maxPoints(&scoreboard, reindeer.items, time)});
    }

    try stdout.flush();
}

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
