const std = @import("std");

const solver = @import("../solver.zig");

const DevMap = std.AutoHashMapUnmanaged(u32, std.ArrayList(u32));
const PathCache = std.AutoArrayHashMapUnmanaged(u32, struct { usize, u2 });

const dac = convertDevName("dac");
const fft = convertDevName("fft");

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?usize, ?usize } {
    const gpa = tools.gpa;
    var devices: DevMap = .empty;
    defer {
        var it = devices.valueIterator();
        while (it.next()) |d| d.deinit(gpa);
        devices.deinit(gpa);
    }
    while (try input.reader.takeDelimiter('\n')) |line| {
        var outputs: std.ArrayList(u32) = .empty;
        for (line[5..], 5..) |c, i| {
            if (c == ' ') {
                try outputs.append(gpa, convertDevName(line[i - 3 .. i]));
            }
        }
        try outputs.append(gpa, convertDevName(line[line.len - 3 ..]));
        try devices.put(gpa, convertDevName(line[0..3]), outputs);
    }
    var cache: PathCache = .empty;
    defer cache.deinit(gpa);
    const answer1, _ = try countPaths(gpa, devices, &cache, convertDevName("you"), convertDevName("out"), 0);
    const answer2, _ = try countPaths(gpa, devices, &cache, convertDevName("svr"), convertDevName("out"), 2);
    return .{ answer1, if (answer2 < 2) null else answer2 };
}

pub const solve = solver.intSolver(usize, solveInt);

fn countPaths(
    alloc: std.mem.Allocator,
    devices: DevMap,
    cache: *PathCache,
    start: u32,
    end: u32,
    required: u2,
) solver.Error!struct { usize, u2 } {
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
