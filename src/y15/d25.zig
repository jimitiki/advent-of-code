const std = @import("std");

const lib = @import("lib");

// TODO: Use `modpow`?

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    defer arena.free(args);
    _ = std.meta.stringToEnum(lib.Part, args[2]);
    const row = try std.fmt.parseUnsigned(u64, args[3], 10);
    const col = try std.fmt.parseUnsigned(u64, args[4], 10);

    var code: u64 = 20151125;
    compute: for (2..row + col) |i| {
        for (1..i + 1) |c| {
            const r = i + 1 - c;
            code = (code * 252533) % 33554393;
            if (c == col and r == row) {
                break :compute;
            }
        }
    }

    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer: std.Io.File.Writer = .init(.stdout(), init.io, &stdout_buffer);
    var stdout = &stdout_writer.interface;
    try stdout.print("{}\n", .{code});
    try stdout.flush();
}
