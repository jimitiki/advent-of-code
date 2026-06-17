const std = @import("std");

const solver = @import("../solver.zig");

const keypad_p1 = [_][3]u8{
    [_]u8{ '1', '2', '3' },
    [_]u8{ '4', '5', '6' },
    [_]u8{ '7', '8', '9' },
};

const keypad_p2 = [_][5]?u8{
    [_]?u8{ null, null, '1', null, null },
    [_]?u8{ null, '2', '3', '4', null },
    [_]?u8{ '5', '6', '7', '8', '9' },
    [_]?u8{ null, 'A', 'B', 'C', null },
    [_]?u8{ null, null, 'D', null, null },
};

pub fn solve(input: solver.Input, tools: solver.Tools, p1buf: *[32]u8, p2buf: *[32]u8) solver.Error!struct { ?[]const u8, ?[]const u8 } {
    var keys_p1: std.ArrayList(u8) = .empty;
    defer keys_p1.deinit(tools.gpa);
    var keys_p2: std.ArrayList(u8) = .empty;
    defer keys_p2.deinit(tools.gpa);

    var row_p1: u2 = 1;
    var col_p1: u2 = 1;
    var row_p2: u3 = 2;
    var col_p2: u3 = 0;
    while (try input.reader.takeDelimiter('\n')) |line| {
        for (line) |char| {
            switch (char) {
                'U' => {
                    row_p1 -|= 1;
                    if (keypad_p2[row_p2 -| 1][col_p2]) |_| row_p2 -|= 1;
                },
                'D' => {
                    row_p1 = @min(2, row_p1 + 1);
                    if (keypad_p2[@min(4, row_p2 + 1)][col_p2]) |_| row_p2 = @min(4, row_p2 + 1);
                },
                'L' => {
                    col_p1 -|= 1;
                    if (keypad_p2[row_p2][col_p2 -| 1]) |_| col_p2 -|= 1;
                },
                'R' => {
                    col_p1 = @min(2, col_p1 + 1);
                    if (keypad_p2[row_p2][@min(4, col_p2 + 1)]) |_| col_p2 = @min(4, col_p2 + 1);
                },
                else => return error.InvalidInput,
            }
        }
        try keys_p1.append(tools.gpa, keypad_p1[row_p1][col_p1]);
        try keys_p2.append(tools.gpa, keypad_p2[row_p2][col_p2].?);
    }
    const code_p1 = p1buf[0..keys_p1.items.len];
    @memcpy(code_p1, keys_p1.items);
    const code_p2 = p2buf[0..keys_p2.items.len];
    @memcpy(code_p2, keys_p2.items);
    return .{ code_p1, code_p2 };
}
