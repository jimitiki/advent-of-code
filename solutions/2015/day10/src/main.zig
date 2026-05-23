const std = @import("std");

// TODO: Use "elements": https://en.wikipedia.org/wiki/Look-and-say_sequence#Cosmological_decay

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    defer arena.free(args);
    const seed = args[2];
    const iterations = try std.fmt.parseUnsigned(usize, args[3], 10);

    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer: std.Io.File.Writer = .init(.stdout(), init.io, &stdout_buffer);
    var stdout = &stdout_writer.interface;

    var buf_cur: []u8 = try arena.alloc(u8, seed.len);
    defer arena.free(buf_cur);
    for (seed, 0..) |char, i| {
        buf_cur[i] = char - 48;
    }
    var sequence: []const u8 = buf_cur;
    for (0..iterations) |_| {
        const buf_next: []u8 = try arena.alloc(u8, sequence.len * 2);
        const next_sequence: []const u8 = lookSay(sequence, buf_next);
        arena.free(buf_cur);
        buf_cur = buf_next;
        sequence = next_sequence;
    }

    try stdout.print("{}\n", .{sequence.len});
    try stdout.flush();
}

fn lookSay(sequence: []const u8, buf: []u8) []const u8 {
    var i: usize = 0;
    var j: usize = 0;
    while (i < sequence.len) : (i += 1) {
        const digit = sequence[i];
        var count: u8 = 1;
        while (i + count < sequence.len and sequence[i + count] == digit) : (count += 1) {}
        buf[j] = count;
        j += 1;
        buf[j] = digit;
        j += 1;
        i += count - 1;
    }
    return buf[0..j];
}
