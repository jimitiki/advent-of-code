const std = @import("std");

const lib = @import("lib");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    defer arena.free(args);
    const target = try std.fmt.parseUnsigned(u32, args[3], 10);

    var house: u32 = 1;
    while (sumFactors(house) * 10 < target) : (house += 1) {}

    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer: std.Io.File.Writer = .init(.stdout(), init.io, &stdout_buffer);
    var stdout = &stdout_writer.interface;
    try stdout.print("{}\n", .{house});
    try stdout.flush();
}

fn sumFactors(number: u32) u32 {
    if (number == 0) {
        return 0;
    } else if (number == 1) {
        return 1;
    }

    var sum: u32 = 1 + number;
    const cutoff = @sqrt(@as(f64, @floatFromInt(number)));
    var factor: u32 = 2;
    while (factor <= cutoff) : (factor += 1) {
        if (number % factor == 0) {
            sum += factor;
            const other = number / factor;
            if (factor != other) sum += other;
        }
    }
    return sum;
}
