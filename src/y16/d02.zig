const std = @import("std");

const solver = @import("../solver.zig");

const keypad = [_][3]u8{
    [_]u8{ '1', '2', '3' },
    [_]u8{ '4', '5', '6' },
    [_]u8{ '7', '8', '9' },
};

pub fn solve(gpa: std.mem.Allocator, input: *std.Io.Reader, buf1: []u8, buf2: []u8) solver.Error!struct { ?[]const u8, ?[]const u8 } {
    _ = buf2;
    var keys: std.ArrayList(u8) = .empty;
    defer keys.deinit(gpa);

    var row: u2 = 1;
    var col: u2 = 1;
    while (try input.takeDelimiter('\n')) |line| {
        for (line) |char| {
            switch (char) {
                'U' => row -|= 1,
                'D' => row = @min(2, row + 1),
                'L' => col -|= 1,
                'R' => col = @min(2, col + 1),
                else => return error.InvalidInput,
            }
        }
        try keys.append(gpa, keypad[row][col]);
    }
    const code = buf1[0..keys.items.len];
    @memcpy(code, keys.items);
    return .{ code, null };
}
