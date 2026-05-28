const std = @import("std");
const assert = std.debug.assert;

const solver = @import("../solver.zig");

fn solveInt(_: std.mem.Allocator, input: *std.Io.Reader) solver.Error!struct { ?u32, ?u32 } {
    var dial: u8 = 50;
    var pwd1: u32 = 0;
    var pwd2: u32 = 0;
    while (try input.takeDelimiter('\n')) |line| {
        const dir = line[0];
        const mag = std.fmt.parseInt(u16, line[1..line.len], 10) catch return error.InvalidInput;
        const change: i32 = if (dir == 'L') -@as(i32, mag) else if (dir == 'R') mag else unreachable;
        pwd1 += test_line_p1(dial, change);
        pwd2 += test_line_p2(dial, change);
        dial = @intCast(@mod(@as(i32, dial) + change, 100));
    }
    return .{ pwd1, pwd2 };
}

pub const solve = solver.intSolver(u32, solveInt);

fn test_line_p1(pos: u8, change: i32) u8 {
    return if (@mod(pos + change, 100) == 0) 1 else 0;
}

fn test_line_p2(pos: u8, change: i32) u8 {
    if (change > 0) {
        return @intCast(@divFloor(change + pos, 100));
    } else {
        const full_turns: u8 = @intCast(@divFloor(@abs(change), 100));
        const extra: u8 = @intCast(100 - @mod(change, 100));
        if (pos != 0 and extra >= pos) {
            return full_turns + 1;
        } else {
            return full_turns;
        }
    }
}
