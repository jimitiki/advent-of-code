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

    try stdout.print("{}\n", .{countCombinations(containers.items, 0)});
    try stdout.flush();
}

fn countCombinations(containers: []u32, capacity: u32) u32 {
    if (capacity == 150) {
        return 1;
    } else if (capacity > 150) {
        return 0;
    } else if (containers.len == 0) {
        return 0;
    }

    var count: u32 = 0;
    for (containers, 0..) |container, i| {
        count += countCombinations(containers[i + 1 ..], capacity + container);
    }
    return count;
}
