const std = @import("std");

const solver = @import("../solver.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    return .{ try analyzeStream(tools.input), null };
}

fn analyzeStream(reader: *std.Io.Reader) error{ReadFailed}!u16 {
    var depth: u8 = 0;
    var score: u16 = 0;
    var garbage = false;
    while (true) {
        const c = reader.takeByte() catch break;
        switch (c) {
            '!' => _ = try reader.discardShort(1),
            '>' => garbage = false,
            '<' => garbage = true,
            '{' => {
                if (!garbage) {
                    depth += 1;
                    score += depth;
                }
            },
            '}' => {
                if (!garbage) {
                    depth -= 1;
                }
            },
            else => {},
        }
    }
    return score;
}

pub const solve = solver.intSolver(u16, solveInt);
