const std = @import("std");
const lib = @import("lib");

const solver = lib.solver;
const testing = lib.testing;

const Pos = struct { i16, i16 };
const State = enum { weakened, infected, flagged };
const Dir = enum {
    up,
    down,
    left,
    right,

    fn turnLeft(self: Dir) Dir {
        return switch (self) {
            .up => .left,
            .down => .right,
            .left => .down,
            .right => .up,
        };
    }

    fn turnRight(self: Dir) Dir {
        return switch (self) {
            .up => .right,
            .down => .left,
            .left => .up,
            .right => .down,
        };
    }

    fn reverse(self: Dir) Dir {
        return switch (self) {
            .up => .down,
            .down => .up,
            .left => .right,
            .right => .left,
        };
    }

    fn move(self: Dir, pos: Pos) Pos {
        return switch (self) {
            .up => .{ pos[0], pos[1] - 1 },
            .down => .{ pos[0], pos[1] + 1 },
            .left => .{ pos[0] - 1, pos[1] },
            .right => .{ pos[0] + 1, pos[1] },
        };
    }
};

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    const gpa = tools.gpa;
    var initial: std.ArrayList(Pos) = .empty;
    defer initial.deinit(gpa);

    var y: u16 = 0;
    var start: Pos = .{ undefined, undefined };
    var reader = input.reader();
    while (try reader.takeDelimiter('\n')) |line| : (y += 1) {
        if (y == 0) {
            start[0] = @intCast(@divExact(line.len - 1, 2));
        }
        for (line, 0..) |char, x| {
            if (char == '#') try initial.append(gpa, .{ @intCast(x), @intCast(y) });
        }
    }
    start[1] = @intCast(@divExact(y - 1, 2));

    var infected: std.AutoHashMapUnmanaged(Pos, State) = .empty;
    defer infected.deinit(gpa);
    try infected.ensureTotalCapacity(gpa, @intCast(initial.items.len));
    for (initial.items) |p| {
        infected.putAssumeCapacity(p, .infected);
    }

    var pos = start;
    var dir: Dir = .up;
    var p1: u32 = 0;
    for (0..10000) |_| {
        if ((try infected.getOrPut(gpa, pos)).found_existing) {
            _ = infected.remove(pos);
            dir = dir.turnRight();
        } else {
            dir = dir.turnLeft();
            p1 += 1;
        }
        pos = dir.move(pos);
    }

    infected.clearRetainingCapacity();
    for (initial.items) |p| {
        infected.putAssumeCapacity(p, .infected);
    }

    pos = start;
    dir = .up;
    var p2: u32 = 0;
    for (0..10_000_000) |_| {
        const result = try infected.getOrPut(gpa, pos);
        if (result.found_existing) {
            switch (result.value_ptr.*) {
                .flagged => {
                    _ = infected.remove(pos);
                    dir = dir.reverse();
                },
                .infected => {
                    dir = dir.turnRight();
                    result.value_ptr.* = .flagged;
                },
                .weakened => {
                    result.value_ptr.* = .infected;
                    p2 += 1;
                },
            }
        } else {
            result.value_ptr.* = .weakened;
            dir = dir.turnLeft();
        }
        pos = dir.move(pos);
    }
    return .{ p1, p2 };
}

pub const solve = solver.intSolver(u32, solveInt);

test "solve" {
    if (true) return; // Test is too slow to run with everything else.
    const input =
        \\..#
        \\#..
        \\...
    ;
    try testing.expectIntSolution(u32, solveInt, .{ 5587, 2511944 }, input);
}
