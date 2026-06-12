const std = @import("std");

const solver = @import("../solver.zig");
const t = @import("../test.zig");

const Spinlock = struct {
    buf: *[2018]u16,
    step: u16,
    size: usize = 1,
    index: usize = 0,

    pub fn init(buf: *[2018]u16, step: u16) Spinlock {
        buf[0] = 0;
        return .{ .buf = buf, .step = step };
    }

    pub fn insert(self: *Spinlock, item: u16) void {
        self.index = self.bufIndex(self.index + self.step) + 1;
        @memmove(self.buf[self.index + 1 .. self.size + 1], self.buf[self.index..self.size]);
        self.buf[self.index] = item;
        self.size += 1;
    }

    pub fn bufIndex(self: Spinlock, index: usize) usize {
        return index % self.size;
    }
};

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    const input = try tools.input.takeDelimiter('\n') orelse return error.InvalidInput;
    const step = std.fmt.parseInt(u16, input, 10) catch return error.InvalidInput;
    var buf: [2018]u16 = undefined;
    var spinlock: Spinlock = .init(&buf, step);

    for (1..2018) |i| {
        spinlock.insert(@intCast(i));
    }
    return .{ spinlock.buf[spinlock.bufIndex(spinlock.index + 1)], null };
}

pub const solve = solver.intSolver(u16, solveInt);

test "solve" {
    try t.expectIntSolution(u16, solveInt, .{ 638, null }, "3");
}
