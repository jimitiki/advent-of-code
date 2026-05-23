const std = @import("std");

const lib = @import("lib");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    defer arena.free(args);
    const part = std.meta.stringToEnum(lib.Part, args[2]);
    const target = try std.fmt.parseUnsigned(u32, args[3], 10);

    var house: u32 = 1;
    const sum_fn: *const fn (u32) u32 = if (part == .p1) sumPresents else sumPresentsModified;
    while (sum_fn(house) < target) : (house += 1) {}

    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer: std.Io.File.Writer = .init(.stdout(), init.io, &stdout_buffer);
    var stdout = &stdout_writer.interface;
    try stdout.print("{}\n", .{house});
    try stdout.flush();
}

fn sumPresents(house: u32) u32 {
    if (house == 1) {
        return 10;
    }

    var sum: u32 = 1 + house;
    const sqrt = @sqrt(@as(f64, @floatFromInt(house)));
    const cutoff: u32 = @round(sqrt);
    var divisor: u32 = 2;
    while (divisor <= cutoff) : (divisor += 1) {
        if (house % divisor != 0) {
            continue;
        }
        const quotient = house / divisor;
        sum += divisor;
        if (divisor != quotient) sum += quotient;
    }
    return sum * 10;
}

fn sumPresentsModified(house: u32) u32 {
    if (house == 1) {
        return 10;
    }

    var sum: u32 = house;
    if (house <= 50) {
        sum += 1;
    }
    const sqrt = @sqrt(@as(f64, @floatFromInt(house)));
    const cutoff: u32 = @min(50, @as(u32, @round(sqrt)));
    var divisor: u32 = 2;
    while (divisor <= cutoff) : (divisor += 1) {
        if (house % divisor != 0) {
            continue;
        }
        const quotient = house / divisor;
        if (quotient <= 50) {
            sum += divisor;
        }
        if (divisor != quotient) sum += quotient;
    }
    return sum * 11;
}
