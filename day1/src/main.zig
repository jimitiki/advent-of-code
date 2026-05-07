const std = @import("std");
const Io = std.Io;
const assert = std.debug.assert;

const inputs = [_][]const u8{
    "L68",
    "L30",
    "R48",
    "L5",
    "R60",
    "L55",
    "L1",
    "L99",
    "R14",
    "L82",
};

var dial: i32 = 50;

pub fn main() !void {
    var zeroes: u32 = 0;
    for (inputs) |input| {
        const dir = input[0];
        const mag = try std.fmt.parseInt(u16, input[1..input.len], 10);
        if (dir == 'L') {
            dial = @mod(dial - mag, 100);
        } else if (dir == 'R') {
            dial = @mod(dial + mag, 100);
        } else {
            unreachable;
        }
        if (dial == 0) {
            zeroes += 1;
        }
    }
    std.debug.print("{}\n", .{zeroes});
}
