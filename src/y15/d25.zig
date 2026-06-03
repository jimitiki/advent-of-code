const std = @import("std");

const solver = @import("../solver.zig");
const WordIterator = @import("../parse.zig").WordIterator;

// TODO: Use `modpow`?

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u64, ?u64 } {
    const line = (try tools.input.takeDelimiter('\n')) orelse return error.InvalidInput;
    var it: WordIterator = .{ .string = line, .omit_punctuation = true, .reverse = true, .index = line.len - 1 };
    const col = std.fmt.parseUnsigned(
        u64,
        it.next() orelse return error.InvalidInput,
        10,
    ) catch return error.InvalidInput;
    _ = it.next();
    const row = std.fmt.parseUnsigned(
        u64,
        it.next() orelse return error.InvalidInput,
        10,
    ) catch return error.InvalidInput;

    var code: u64 = 20151125;
    compute: for (2..row + col) |i| {
        for (1..i + 1) |c| {
            const r = i + 1 - c;
            code = (code * 252533) % 33554393;
            if (c == col and r == row) {
                break :compute;
            }
        }
    }
    return .{ code, null };
}

pub const solve = solver.intSolver(u64, solveInt);
