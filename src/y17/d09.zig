const std = @import("std");

const solver = @import("../solver.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    return try analyzeStream(tools.input);
}

fn analyzeStream(reader: *std.Io.Reader) error{ReadFailed}!struct { u16, u16 } {
    var depth: u8 = 0;
    var score: u16 = 0;
    var in_garbage = false;
    var garbage_count: u16 = 0;
    while (true) {
        const c = reader.takeByte() catch break;
        switch (c) {
            '!' => _ = try reader.discardShort(1),
            '>' => in_garbage = false,
            '<' => {
                if (in_garbage) {
                    garbage_count += 1;
                } else {
                    in_garbage = true;
                }
            },
            '{' => {
                if (!in_garbage) {
                    depth += 1;
                    score += depth;
                } else {
                    garbage_count += 1;
                }
            },
            '}' => {
                if (!in_garbage) {
                    depth -= 1;
                } else {
                    garbage_count += 1;
                }
            },
            else => {
                if (in_garbage) {
                    garbage_count += 1;
                }
            },
        }
    }
    return .{ score, garbage_count };
}

pub const solve = solver.intSolver(u16, solveInt);
