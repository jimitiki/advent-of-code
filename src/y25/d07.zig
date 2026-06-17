const std = @import("std");

const solver = @import("../solver.zig");

// TODO: Create a visualization

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u64, ?u64 } {
    const width = checkwidth: {
        const first_line = tools.input.reader.peekDelimiterExclusive('\n') catch return error.InvalidInput;
        break :checkwidth first_line.len;
    };
    const paths = try tools.gpa.alloc(u64, width);
    defer tools.gpa.free(paths);
    var next = try tools.gpa.alloc(u64, width);
    defer tools.gpa.free(next);
    @memset(paths, 0);
    @memset(next, 0);
    var splits: u64 = 0;
    while (try tools.input.reader.takeDelimiter('\n')) |line| {
        for (line, 0..) |c, i| {
            switch (c) {
                'S' => next[i] = 1,
                '.' => next[i] += paths[i],
                '^' => {
                    if (i == 0 or i == line.len - 1) return error.InvalidInput;
                    if (line[i + 1] == '^') return error.InvalidInput;
                    if (paths[i] > 0) {
                        next[i - 1] += paths[i];
                        next[i + 1] += paths[i];
                        splits += 1;
                    }
                },
                else => unreachable,
            }
        }
        @memcpy(paths, next);
        @memset(next, 0);
    }

    var total_paths: u64 = 0;
    for (paths) |path_cnt| total_paths += path_cnt;
    return .{ splits, total_paths };
}

pub const solve = solver.intSolver(u64, solveInt);
