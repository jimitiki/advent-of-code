const std = @import("std");

const solver = @import("../solver.zig");
const t = @import("../test.zig");

// TODO: Implement part 1 without shifting memory at every step.

const Spinlock = struct {
    buf: *[2018]u64,
    step: u64,
    size: usize = 1,
    index: usize = 0,

    pub fn init(buf: *[2018]u64, step: u64) Spinlock {
        buf[0] = 0;
        return .{ .buf = buf, .step = step };
    }

    pub fn insert(self: *Spinlock, item: u64) void {
        self.index = self.bufIndex(self.index + self.step) + 1;
        @memmove(self.buf[self.index + 1 .. self.size + 1], self.buf[self.index..self.size]);
        self.buf[self.index] = item;
        self.size += 1;
    }

    pub fn bufIndex(self: Spinlock, index: usize) usize {
        return index % self.size;
    }
};

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u64, ?u64 } {
    const input = try tools.input.reader.takeDelimiter('\n') orelse return error.InvalidInput;
    const step = std.fmt.parseInt(u64, input, 10) catch return error.InvalidInput;
    var buf: [2018]u64 = undefined;
    var spinlock: Spinlock = .init(&buf, step);

    for (1..2018) |i| {
        spinlock.insert(@intCast(i));
    }

    var index: usize = 0;
    var p2: u64 = 0;
    for (1..50_000_000) |i| {
        index = (index + step) % i + 1;
        if (index == 1) {
            p2 = i;
        }
    }
    return .{ spinlock.buf[spinlock.bufIndex(spinlock.index + 1)], p2 };
}

pub const solve = solver.intSolver(u64, solveInt);

test "solve" {
    try t.expectIntSolution(u64, solveInt, .{ 638, 1222153 }, "3");
}
