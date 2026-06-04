const std = @import("std");

const solver = @import("../solver.zig");
const WordIterator = @import("../parse.zig").WordIterator;

const Disc = struct {
    holes: u8,
    start: u8,

    pub fn position(self: Disc, t: usize) u8 {
        return @intCast((t + self.start) % self.holes);
    }
};

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

fn parseDisc(str: []const u8) error{InvalidInput}!Disc {
    var it: WordIterator = .init(str);
    for (0..3) |_| _ = it.next();
    const holes = it.next() orelse return error.InvalidInput;
    for (0..7) |_| _ = it.next();
    const start = it.next() orelse return error.InvalidInput;
    return .{
        .holes = std.fmt.parseUnsigned(u8, holes, 10) catch return error.InvalidInput,
        .start = std.fmt.parseUnsigned(u8, start[0 .. start.len - 1], 10) catch return error.InvalidInput,
    };
}

fn calculateTime(discs: []Disc) usize {
    var t: usize = 0;
    while (true) : (t += 1) {
        for (discs, 1..) |d, n| {
            if (d.position(t + n) != 0) break;
        } else return t;
    }
}
