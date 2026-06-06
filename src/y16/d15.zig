const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

const Disc = struct {
    holes: u8,
    start: u8,

    pub fn position(self: Disc, t: usize) u8 {
        return @intCast((t + self.start) % self.holes);
    }
};

// TODO: Optimize further. Chinese Remainder Theorem?

fn solveInt(tools: solver.Tools) solver.Error!struct { ?usize, ?usize } {
    var discs: std.ArrayList(Disc) = .empty;
    defer discs.deinit(tools.gpa);
    while (try tools.input.takeDelimiter('\n')) |line| {
        try discs.append(tools.gpa, try parseDisc(line));
    }
    const p1 = calculateTime(discs.items);
    try discs.append(tools.gpa, .{ .holes = 11, .start = 0 });
    return .{ p1, calculateTime(discs.items) };
}

pub const solve = solver.intSolver(usize, solveInt);

fn parseDisc(str: []const u8) Parser.Error!Disc {
    var parser: Parser = .init(str, .{});
    try parser.skipMany(3);
    const holes = try parser.takeInt(u8);
    try parser.skipMany(7);
    const start = try parser.takeInt(u8);
    return .{ .holes = holes, .start = start };
}

fn calculateTime(discs: []Disc) ?usize {
    for (discs, 0..) |a, i| {
        for (discs[i..], i..) |b, j| {
            if (a.holes == b.holes and (a.start + i) % a.holes != (b.start + j) % b.holes) {
                return null;
            }
        }
    }
    var t: usize = 0;
    var step: u8 = 1;
    for (discs, 1..) |disc, i| {
        if (disc.holes > step) {
            step = disc.holes;
            t = disc.holes - (disc.start + i) % disc.holes;
        }
    }
    while (true) : (t += step) {
        for (discs, 1..) |d, n| {
            if (d.position(t + n) != 0) break;
        } else return t;
    }
}
