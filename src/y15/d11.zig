const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    defer arena.free(args);
    const old = args[2];

    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer: std.Io.File.Writer = .init(.stdout(), init.io, &stdout_buffer);
    var stdout = &stdout_writer.interface;

    const pw: []u8 = try arena.alloc(u8, old.len);
    @memcpy(pw, old);
    defer arena.free(pw);
    try increment(pw);
    while (!isValid(pw)) : (try increment(pw)) {}

    try stdout.print("{s}\n", .{pw});
    try stdout.flush();
}

fn increment(pw: []u8) !void {
    for (1..pw.len + 1) |i| {
        const pos = pw.len - i;
        pw[pos] = (pw[pos] - 96) % 26 + 97;
        if (pw[pos] != 'a') {
            break;
        }
    } else return error.Unsolvable;
}

fn isValid(pw: []u8) bool {
    const straight = for (pw[0 .. pw.len - 2], pw[1 .. pw.len - 1], pw[2..pw.len]) |c1, c2, c3| {
        if (c1 + 1 == c2 and c2 + 1 == c3) {
            break true;
        }
    } else false;
    const legal = for (pw) |char| {
        if (char == 'i' or char == 'l' or char == 'o') {
            break false;
        }
    } else true;
    const two_pairs = pair: for (0..pw.len - 3) |i| {
        if (pw[i] != pw[i + 1]) {
            continue;
        }
        for (i + 2..pw.len - 1) |j| {
            if (pw[j] == pw[j + 1] and pw[j] != pw[i]) {
                break :pair true;
            }
        }
    } else false;
    return straight and legal and two_pairs;
}
