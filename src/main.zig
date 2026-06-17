const std = @import("std");

const solver = @import("solver.zig");
const solutions = @import("solutions.zig");

const CountingAllocator = @import("CountingAllocator.zig");
const Parser = @import("Parser.zig");

pub fn main(init: std.process.Init) !void {
    var stdout_buf: [256]u8 = undefined;
    var stdout: std.Io.File.Writer = .init(.stdout(), init.io, &stdout_buf);
    var writer = &stdout.interface;

    var counting_allocator: CountingAllocator = .init(init.gpa);
    const gpa = counting_allocator.allocator();

    const allocator = init.arena.allocator();
    const args = init.minimal.args.toSlice(allocator) catch unreachable;
    if (args.len < 4) return error.MissingArg;
    const year = std.fmt.parseUnsigned(u8, args[2], 10) catch std.debug.panic("Invalid year argument {s}", .{args[2]});
    const day = std.fmt.parseUnsigned(u8, args[3], 10) catch std.debug.panic("Invalid day argument {s}", .{args[3]});

    const input_path = std.fmt.allocPrint(
        allocator,
        "{s}/y{}/d{:0>2}.txt",
        .{ args[1], year, day },
    ) catch unreachable;
    std.debug.print("{s}\n", .{input_path});
    const text = try std.Io.Dir.cwd().readFileAlloc(init.io, input_path, allocator, .unlimited);
    var reader = std.Io.Reader.fixed(text);
    const input: solver.Input = .{ .parser = .init(text, .{}), .reader = &reader, .text = text };
    var answer_buf: [64]u8 = undefined;
    const tools: solver.Tools = .{ .gpa = gpa, .p1buf = answer_buf[0..32], .p2buf = answer_buf[32..], .stdout = writer };
    const solution = solutions.get(year, day) catch std.debug.panic("Invalid year and/or day ({}, {})", .{ year, day });

    const start = std.Io.Clock.real.now(init.io);
    if (solution(input, tools)) |result| {
        const elapsed = start.durationTo(std.Io.Clock.real.now(init.io));
        try printResult(writer, counting_allocator, elapsed, result);
    } else |err| {
        try writer.print("Error while running solver: {}\n", .{err});
        try writer.flush();
    }
}

fn printResult(
    writer: *std.Io.Writer,
    counting_allocator: CountingAllocator,
    elapsed: std.Io.Duration,
    result: solver.Result,
) !void {
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
    try writer.print(
        "Allocated memory - Peak: {}B | Cumulative: {}B\n",
        .{ counting_allocator.peak, counting_allocator.total },
    );
    try writer.print(
        "Elapsed time: {}.{:0>6} seconds\n",
        .{ elapsed.toSeconds(), @abs(elapsed.toMicroseconds()) % 1000000 },
    );
    try writer.flush();
}
