const std = @import("std");
const solver = @import("solver.zig");

const Parser = @import("Parser.zig");

test "test all" {
    _ = @import("y16/asm.zig");
    _ = @import("y16/d04.zig");
    _ = @import("y16/d05.zig");
    _ = @import("y16/d06.zig");
    _ = @import("y16/d07.zig");
    _ = @import("y16/d08.zig");
    _ = @import("y16/d09.zig");
    _ = @import("y16/d10.zig");
    _ = @import("y16/d11.zig");
    _ = @import("y16/d12.zig");
    _ = @import("y16/d13.zig");
    _ = @import("y16/d14.zig");
    _ = @import("y16/d15.zig");
    _ = @import("y16/d16.zig");
    _ = @import("y16/d17.zig");
    _ = @import("y16/d18.zig");
    _ = @import("y16/d19.zig");
    _ = @import("y16/d20.zig");
    _ = @import("y16/d21.zig");
    _ = @import("y16/d22.zig");
    _ = @import("y16/d23.zig");
    _ = @import("y16/d24.zig");
    _ = @import("y16/d25.zig");

    _ = @import("y17/KnotHasher.zig");
    _ = @import("y17/d01.zig");
    _ = @import("y17/d02.zig");
    _ = @import("y17/d03.zig");
    _ = @import("y17/d04.zig");
    _ = @import("y17/d05.zig");
    _ = @import("y17/d06.zig");
    _ = @import("y17/d07.zig");
    _ = @import("y17/d08.zig");
    _ = @import("y17/d09.zig");
    _ = @import("y17/d10.zig");
    _ = @import("y17/d11.zig");
    _ = @import("y17/d12.zig");
    _ = @import("y17/d13.zig");
    _ = @import("y17/d14.zig");
    _ = @import("y17/d15.zig");
    _ = @import("y17/d16.zig");
    _ = @import("y17/d17.zig");
    _ = @import("y17/d18.zig");
    _ = @import("y17/d19.zig");
    _ = @import("y17/d20.zig");
    _ = @import("y17/d21.zig");
    _ = @import("y17/d22.zig");
    _ = @import("y17/d23.zig");
    _ = @import("y17/d24.zig");
    _ = @import("y17/d25.zig");
    _ = @import("y18/d01.zig");
    _ = @import("y18/d02.zig");
    _ = @import("y18/d03.zig");
}

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
