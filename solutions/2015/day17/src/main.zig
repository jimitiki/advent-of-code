const std = @import("std");

const lib = @import("lib");
const Boilerplate = lib.Boilerplate;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;

    var containers: std.ArrayList(u32) = .empty;
    defer containers.deinit(bp.arena);

    while (try input.takeDelimiter('\n')) |line| {
        try containers.append(bp.arena, try std.fmt.parseUnsigned(u32, line, 10));
    }

    if (bp.part == .p1) {
        try stdout.print("{}\n", .{countCombinations(containers.items, 0, 0, 0)});
    } else {
        const limit = minUsed(containers.items, 0, 0);
        try stdout.print("{}\n", .{countCombinations(containers.items, 0, 0, limit)});
    }

    try stdout.flush();
}

fn countCombinations(containers: []u32, capacity: u32, used: u32, limit: u32) u32 {
    if (limit > 0 and used > limit) {
        return 0;
    } else if (capacity == 150) {
        return 1;
    } else if (capacity > 150) {
        return 0;
    } else if (containers.len == 0) {
        return 0;
    }

    var count: u32 = 0;
    for (containers, 0..) |container, i| {
        count += countCombinations(containers[i + 1 ..], capacity + container, used + 1, limit);
    }
    return count;
}

fn minUsed(containers: []u32, capacity: u32, used: u32) u32 {
    if (capacity == 150) {
        return used;
    } else if (capacity > 150) {
        return std.math.maxInt(u32);
    } else if (containers.len == 0) {
        return std.math.maxInt(u32);
    }

    var min_used: u32 = std.math.maxInt(u32);
    for (containers, 0..) |container, i| {
        min_used = @min(min_used, minUsed(containers[i + 1 ..], capacity + container, used + 1));
    }
    return min_used;
}
