const std = @import("std");

const solver = @import("../solver.zig");
const t = @import("../test.zig");

const Pos = struct { i16, i16 };
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

    fn move(self: Dir, pos: Pos) Pos {
        return switch (self) {
            .up => .{ pos[0], pos[1] - 1 },
            .down => .{ pos[0], pos[1] + 1 },
            .left => .{ pos[0] - 1, pos[1] },
            .right => .{ pos[0] + 1, pos[1] },
        };
    }
};

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    var infected: std.AutoHashMapUnmanaged(Pos, void) = .empty;
    defer infected.deinit(tools.gpa);

    var y: u16 = 0;
    var pos: Pos = .{ undefined, undefined };
    while (try tools.input.takeDelimiter('\n')) |line| : (y += 1) {
        if (y == 0) {
            pos[0] = @intCast(@divExact(line.len - 1, 2));
        }
        for (line, 0..) |char, x| {
            if (char == '#') try infected.put(tools.gpa, .{ @intCast(x), @intCast(y) }, {});
        }
    }
    pos[1] = @intCast(@divExact(y - 1, 2));

    var dir: Dir = .up;
    var infections: u16 = 0;
    for (0..10000) |_| {
        if ((try infected.getOrPut(tools.gpa, pos)).found_existing) {
            _ = infected.remove(pos);
            dir = dir.turnRight();
        } else {
            dir = dir.turnLeft();
            infections += 1;
        }
        pos = dir.move(pos);
    }
    return .{ infections, null };
}

pub const solve = solver.intSolver(u16, solveInt);

test "solve" {
    const input =
        \\..#
        \\#..
        \\...
    ;
    try t.expectIntSolution(u16, solveInt, .{ 5587, null }, input);
}
