const std = @import("std");

const solver = @import("../solver.zig");

const Dir = enum { n, ne, nw, s, se, sw };
const Pos = struct { x: i32, y: i32, z: i32 };

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var x: i32 = 0;
    var y: i32 = 0;
    const z: i32 = 0;
    while (try tools.input.takeDelimiter(',')) |step| {
        const dir = std.meta.stringToEnum(Dir, stripNewline(step)) orelse break;
        switch (dir) {
            .n => y -= 1,
            .s => y += 1,
            .se => x -= 1,
            .nw => x += 1,
            .ne => {
                x -= 1;
                y -= 1;
            },
            .sw => {
                x += 1;
                y += 1;
            },
        }
    }
    const dist = @abs(x) + @abs(y) + @abs(z);
    return .{ dist, null };
}

pub const solve = solver.intSolver(u32, solveInt);

fn stripNewline(str: []const u8) []const u8 {
    return if (str[str.len - 1] == '\n') str[0 .. str.len - 1] else str;
}
