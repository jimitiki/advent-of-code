const std = @import("std");

const solver = @import("solver.zig");
const solutions = @import("solutions.zig");

pub fn main(init: std.process.Init) !void {
    var stdout_buf: [256]u8 = undefined;
    var stdout: std.Io.File.Writer = .init(.stdout(), init.io, &stdout_buf);
    var writer = &stdout.interface;

    var answer_buf: [64]u8 = undefined;
    const start = std.Io.Clock.real.now(init.io);
    if (runSolver(init, writer, answer_buf[0..32], answer_buf[32..])) |result| {
        const elapsed = start.durationTo(std.Io.Clock.real.now(init.io));
        if (result[0]) |answer| {
            try writer.print("Part 1: {s}\n", .{answer});
        } else {
            try writer.print("Part 1: No Answer\n", .{});
        }
        if (result[1]) |answer| {
            try writer.print("Part 2: {s}\n", .{answer});
        } else {
            try writer.print("Part 2: No Answer\n", .{});
        }
        try writer.print("Elapsed time: {}.{:0>6} seconds\n", .{ elapsed.toSeconds(), @abs(elapsed.toMicroseconds()) % 1000000 });
    } else |err| {
        try writer.print("Error while running solver: {}\n", .{err});
    }
    try writer.flush();
}

fn runSolver(init: std.process.Init, stdout: *std.Io.Writer, answer_buf1: *[32]u8, answer_buf2: *[32]u8) !solver.Result {
    const allocator = init.arena.allocator();
    const args = init.minimal.args.toSlice(allocator) catch std.debug.panic("Failed to read arguments", .{});
    const year = std.fmt.parseUnsigned(u8, args[2], 10) catch std.debug.panic("Invalid year argument {s}", .{args[2]});
    const day = std.fmt.parseUnsigned(u8, args[3], 10) catch std.debug.panic("Invalid day argument {s}", .{args[3]});

    const input_path = inputFilePath(allocator, args);
    const input_file = std.Io.Dir.cwd().openFile(init.io, input_path, .{}) catch {
        std.debug.panic("Failed to open file at path {s}", .{input_path});
    };
    defer input_file.close(init.io);

    var read_buf: [4096]u8 = undefined;
    var reader = input_file.reader(init.io, &read_buf);

    const solution = solutions.get(year, day) catch std.debug.panic("Invalid year and/or day ({}, {})", .{ year, day });
    return solution(.{
        .gpa = init.gpa,
        .input = &reader.interface,
        .stdout = stdout,
        .p1buf = answer_buf1,
        .p2buf = answer_buf2,
    });
}

fn inputFilePath(allocator: std.mem.Allocator, args: []const [:0]const u8) []const u8 {
    return std.fmt.allocPrint(
        allocator,
        "{s}/y{s}/d{s:0>2}.txt",
        .{ args[1], args[2], args[3] },
    ) catch std.debug.panic("Ran out of memory", .{});
}
