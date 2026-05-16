const std = @import("std");

const Init = @import("lib").Init;
const DevMap = std.AutoHashMapUnmanaged(u32, std.ArrayList(u32));
const PathCache = std.AutoArrayHashMapUnmanaged(u32, usize);

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var ini = try Init.init(init, &stdout_buffer, &read_buffer);
    defer ini.deinit();

    var stdout = &ini.stdout_writer.interface;
    var input = &ini.input_reader.interface;
    var devices: DevMap = .empty;
    defer {
        var it = devices.valueIterator();
        while (it.next()) |d| d.deinit(ini.arena);
    }
    while (try input.takeDelimiter('\n')) |line| {
        var outputs: std.ArrayList(u32) = .empty;
        for (line[5..], 5..) |c, i| {
            if (c == ' ') {
                try outputs.append(ini.arena, convertDevName(line[i - 3 .. i]));
            }
        }
        try outputs.append(ini.arena, convertDevName(line[line.len - 3 ..]));
        try devices.put(ini.arena, convertDevName(line[0..3]), outputs);
    }
    var cache: PathCache = .empty;
    const answer = try countPaths(ini.arena, devices, &cache, convertDevName("you"), convertDevName("out"));

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn countPaths(alloc: std.mem.Allocator, devices: DevMap, cache: *PathCache, start: u32, end: u32) !usize {
    if (cache.get(start)) |paths| return paths;
    if (start == end) return 1;
    var paths: usize = 0;
    if (devices.get(start)) |outputs| {
        for (outputs.items) |next| {
            paths += try countPaths(alloc, devices, cache, next, end);
        }
    } else std.debug.panic("Unrecognized device name");
    try cache.put(alloc, start, paths);
    return paths;
}

fn convertDevName(name: []const u8) u32 {
    if (name.len != 3) unreachable;
    return (@as(u32, name[0]) << 16) + (@as(u32, name[1]) << 8) + (@as(u32, name[2]));
}
