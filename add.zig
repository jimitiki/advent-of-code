const std = @import("std");

const Solution = struct {
    const Self = @This();
    year: u16,
    day: u8,

    pub fn lessThan(_: void, lhs: Self, rhs: Self) bool {
        if (lhs.year > rhs.year) {
            return false;
        } else if (lhs.year < rhs.year) {
            return true;
        } else {
            return lhs.day < rhs.day;
        }
    }
};

pub fn main(init: std.process.Init) !void {
    const gpa = init.arena.allocator();
    const args = try init.minimal.args.toSlice(gpa);
    const year = 2000 + try std.fmt.parseInt(u16, args[2], 10);
    const day = try std.fmt.parseInt(u8, args[3], 10);

    const dir = try std.Io.Dir.openDirAbsolute(init.io, args[1], .{});
    // std.debug.print("{s}\n", .{path});
    const zon = try dir.readFileAllocOptions(init.io, "solutions/solutions.zon", gpa, .unlimited, .@"1", 0);
    const known_solutions = try std.zon.parse.fromSliceAlloc([]Solution, gpa, zon, null, .{});
    var solutions = std.ArrayList(Solution).fromOwnedSlice(known_solutions);
    for (solutions.items) |s| {
        if (s.year == year and s.day == year) {
            std.debug.print("{} day {} solution already exists", .{ year, day });
            return;
        }
    }
    try solutions.append(gpa, .{ .day = day, .year = year });
    std.sort.pdq(Solution, solutions.items, {}, Solution.lessThan);

    const subpath = try std.fmt.allocPrint(gpa, "solutions/{}/day{}", .{ year, day });
    const subdir = try dir.createDirPathOpen(init.io, subpath, .{});
    try subdir.createDirPath(init.io, "data");
    if (std.Io.Dir.copyFile(dir, "template.zig", subdir, "src/main.zig", init.io, .{ .replace = false, .make_path = true })) |_| {} else |err| {
        switch (err) {
            error.PathAlreadyExists => {},
            else => |e| return e,
        }
    }
    if (subdir.createFile(init.io, "data/real.txt", .{ .exclusive = true })) |_| {} else |err| {
        switch (err) {
            error.PathAlreadyExists => {},
            else => |e| return e,
        }
    }
    if (subdir.createFile(init.io, "data/test.txt", .{ .exclusive = true })) |_| {} else |err| {
        switch (err) {
            error.PathAlreadyExists => {},
            else => |e| return e,
        }
    }

    var buf: [1024]u8 = undefined;
    var solutions_file = try dir.openFile(init.io, "solutions/solutions.zon", .{ .mode = .write_only });
    var writer = solutions_file.writer(init.io, &buf);
    try std.zon.stringify.serialize(solutions.items, .{}, &writer.interface);
    try writer.flush();
}
