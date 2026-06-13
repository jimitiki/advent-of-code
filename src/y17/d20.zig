const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var min_acc: u32 = std.math.maxInt(i32);
    var particle: u32 = undefined;
    var i: u32 = 0;
    while (try tools.input.takeDelimiter('\n')) |line| : (i += 1) {
        var parser: Parser = .init(line, .{});
        try parser.skipMany(6);
        const xstr = try parser.take();
        const acc_x = std.fmt.parseInt(i32, xstr[3..], 10) catch return error.InvalidInput;
        const acc_y = try parser.takeInt(i32);
        const zstr = try parser.take();
        const acc_z = std.fmt.parseInt(i32, zstr[0 .. zstr.len - 1], 10) catch return error.InvalidInput;
        const acc = @abs(acc_x) + @abs(acc_y) + @abs(acc_z);
        if (acc < min_acc) {
            min_acc = acc;
            particle = i;
        }
    }
    return .{ particle, null };
}

pub const solve = solver.intSolver(u32, solveInt);
