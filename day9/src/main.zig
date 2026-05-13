const std = @import("std");

const Init = @import("lib").Init;

const Tile = struct { usize, usize };
const GridRow = std.StaticBitSet(10000);

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var ini = try Init.init(init, &stdout_buffer, &read_buffer);
    defer ini.deinit();

    var stdout = &ini.stdout_writer.interface;
    var input = &ini.input_reader.interface;

    var tiles: std.ArrayList(Tile) = .empty;
    defer tiles.deinit(ini.arena);
    var answer: u64 = 0;
    while (try input.takeDelimiter('\n')) |line| {
        for (line, 0..) |c, i| {
            if (c == ',') {
                try tiles.append(ini.arena, .{
                    try std.fmt.parseUnsigned(u32, line[0..i], 10),
                    try std.fmt.parseUnsigned(u32, line[i + 1 ..], 10),
                });
            }
        }
    }
    for (tiles.items, 0..) |t1, i| {
        for (tiles.items[i..]) |t2| {
            answer = @max(area(t1, t2), answer);
        }
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn area(t1: Tile, t2: Tile) u64 {
    return (1 + @max(t1[0], t2[0]) - @min(t1[0], t2[0])) * (1 + @max(t1[1], t2[1]) - @min(t1[1], t2[1]));
}
