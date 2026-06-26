const std = @import("std");
const solver = @import("solver.zig");

const Parser = @import("Parser.zig");

pub fn expectSolution(
    comptime solveFn: solver.Solver,
    expected: solver.Result,
    text: []const u8,
) !void {
    var buf: [128]u8 = undefined;
    var writer = std.Io.Writer.fixed(buf[0..64]);
    const actual = try solveFn(
        .{ .text = text },
        .{
            .gpa = std.testing.allocator,
            .stdout = &writer,
        },
        buf[64..96],
        buf[96..],
    );
    try std.testing.expectEqualDeep(expected, actual);
}

pub fn expectIntSolution(
    comptime T: type,
    comptime solveFn: fn (solver.Input, solver.Tools) solver.Error!struct { ?T, ?T },
    expected: struct { ?T, ?T },
    text: []const u8,
) !void {
    var buf: [64]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);
    const actual = try solveFn(
        .{ .text = text },
        .{
            .gpa = std.testing.allocator,
            .stdout = &writer,
        },
    );
    try std.testing.expectEqual(expected, actual);
}
