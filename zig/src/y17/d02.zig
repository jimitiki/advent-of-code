const std = @import("std");
const lib = @import("lib");

const solver = lib.solver;
const Parser = lib.Parser;

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    var row: std.ArrayList(u16) = .empty;
    defer row.deinit(tools.gpa);

    var chksum: u16 = 0;
    var divsum: u16 = 0;
    var reader = input.reader();
    while (try reader.takeDelimiter('\n')) |line| : (row.clearRetainingCapacity()) {
        var parser: Parser = .init(line, .{});
        var min: u16 = std.math.maxInt(u16);
        var max: u16 = 0;
        while (true) {
            if (parser.takeInt(u16)) |n| {
                for (row.items) |m| {
                    if (std.math.divExact(u16, n, m)) |q| divsum += q else |_| {}
                    if (std.math.divExact(u16, m, n)) |q| divsum += q else |_| {}
                }
                min = @min(min, n);
                max = @max(max, n);
                try row.append(tools.gpa, n);
            } else |err| {
                switch (err) {
                    error.EndOfBuffer => break,
                    else => |e| return e,
                }
            }
        }
        chksum += max - min;
    }
    return .{ chksum, divsum };
}

pub const solve = solver.intSolver(u16, solveInt);
