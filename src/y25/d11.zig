const std = @import("std");

const Boilerplate = @import("lib").Boilerplate;
const DevMap = std.AutoHashMapUnmanaged(u32, std.ArrayList(u32));
const PathCache = std.AutoArrayHashMapUnmanaged(u32, struct { usize, u2 });

const dac = convertDevName("dac");
const fft = convertDevName("fft");

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;
    var devices: DevMap = .empty;
    defer {
        var it = devices.valueIterator();
        while (it.next()) |d| d.deinit(bp.arena);
    }
    while (try input.takeDelimiter('\n')) |line| {
        var outputs: std.ArrayList(u32) = .empty;
        for (line[5..], 5..) |c, i| {
            if (c == ' ') {
                try outputs.append(bp.arena, convertDevName(line[i - 3 .. i]));
            }
        }
        try outputs.append(bp.arena, convertDevName(line[line.len - 3 ..]));
        try devices.put(bp.arena, convertDevName(line[0..3]), outputs);
    }
    var cache: PathCache = .empty;
    defer cache.deinit(bp.arena);
    const start, const required: u2 = if (bp.part == .p1) .{ convertDevName("you"), 0 } else .{ convertDevName("svr"), 2 };
    const answer = try countPaths(bp.arena, devices, &cache, start, convertDevName("out"), required);
    if (answer[1] < required) return error.Unsolvable;

    try stdout.print("{}\n", .{answer[0]});
    try stdout.flush();
}

fn countPaths(
    alloc: std.mem.Allocator,
    devices: DevMap,
    cache: *PathCache,
    start: u32,
    end: u32,
    required: u2,
) !struct { usize, u2 } {
    if (start == end) {
        return .{ 1, 0 };
    }
    if (cache.get(start)) |rec| return rec;

    var paths: usize = 0;
    var reqs: u2 = 0;
    if (devices.get(start)) |outputs| {
        for (outputs.items) |next| {
            const subpaths, const subreqs = try countPaths(
                alloc,
                devices,
                cache,
                next,
                end,
                required,
            );
            if (subreqs == reqs) {
                paths += subpaths;
            } else if (subreqs > reqs) {
                reqs = subreqs;
                paths = subpaths;
            }
        }
    } else std.debug.panic("Unrecognized device name", .{});
    if (start == dac or start == fft) {
        std.debug.assert(reqs < 2);
        reqs += 1;
    }
    try cache.put(alloc, start, .{ paths, reqs });
    return .{ paths, @min(reqs, required) };
}

fn convertDevName(name: []const u8) u32 {
    if (name.len != 3) unreachable;
    return (@as(u32, name[0]) << 16) + (@as(u32, name[1]) << 8) + (@as(u32, name[2]));
}
