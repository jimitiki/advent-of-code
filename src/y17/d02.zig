const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    var chksum: u16 = 0;
    while (try tools.input.takeDelimiter('\n')) |line| {
        var parser: Parser = .init(line, .{});
        var min: u16 = std.math.maxInt(u16);
        var max: u16 = 0;
        while (true) {
            if (parser.takeInt(u16)) |n| {
                min = @min(min, n);
                max = @max(max, n);
            } else |err| {
                switch (err) {
                    error.EndOfBuffer => break,
                    else => |e| return e,
                }
            }
        }
        chksum += max - min;
    }
    return .{ chksum, null };
}

pub const solve = solver.intSolver(u16, solveInt);
