const std = @import("std");

const lib = @import("lib");
const Boilerplate = lib.Boilerplate;

const Reindeer = struct {
    speed: u32,
    duration: u32,
    rest: u32,
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

    try stdout.print("{}\n", .{maxDistance(reindeer.items, try std.fmt.parseUnsigned(u32, bp.args[4], 10))});
    try stdout.flush();
}

fn maxDistance(reindeer: []Reindeer, time: u32) u32 {
    var max: u32 = 0;
    for (reindeer) |r| {
        const cycles = time / (r.duration + r.rest);
        const remainder = @min(r.duration, time % (r.duration + r.rest));
        const dist_per_cycle = r.speed * r.duration;
        max = @max(max, cycles * dist_per_cycle + remainder * r.speed);
    }
    return max;
}
