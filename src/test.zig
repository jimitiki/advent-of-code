const std = @import("std");
const solver = @import("solver.zig");

test "test all" {
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
}

pub fn initTools(text: []const u8) !solver.Tools {
    const allocator = std.testing.allocator;
    var buf = try allocator.alloc(u8, 64);
    const reader = try allocator.create(std.Io.Reader);
    const writer = try allocator.create(std.Io.Writer);
    reader.* = std.Io.Reader.fixed(text);
    writer.* = std.Io.Writer.fixed(buf[0..64]);

    return .{
        .gpa = allocator,
        .input = reader,
        .stdout = writer,
        .p1buf = try allocator.alloc(u8, 32),
        .p2buf = try allocator.alloc(u8, 32),
    };
}

pub fn deinitTools(tools: *solver.Tools) void {
    const allocator = std.testing.allocator;
    allocator.free(tools.stdout.buffer);
    // allocator.free(tools.stdout.buffer);
    allocator.free(tools.p1buf);
    allocator.free(tools.p2buf);
    allocator.destroy(tools.stdout);
    allocator.destroy(tools.input);
}
