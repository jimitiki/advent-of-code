const std = @import("std");

const solver = @import("../solver.zig");
const duet = @import("duet.zig");

const Parser = @import("../Parser.zig");

// TODO: Use actual threading with a message queue
// TODO: Fix the behavior in part 1. It works for the real input, but the interpreter does not
//       behave as described in the problem spec. Perhaps there should be two modes, one where a
//       rcv with an empty queue skips to the next instruction, and one where it waits.

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?i64, ?i64 } {
    const gpa = tools.gpa;

    var mp1: duet.Interpreter = .init(gpa, 0);
    defer mp1.deinit();
    try mp1.load(input.text);
    while (try mp1.step(&mp1.queue)) {
        switch (mp1.program[mp1.pc]) {
            .rcv => break,
            else => {},
        }
    }

    var m1: duet.Interpreter = .init(gpa, 0);
    defer m1.deinit();
    var m2: duet.Interpreter = .init(gpa, 1);
    defer m2.deinit();
    try m1.load(input.text);
    try m2.load(input.text);
    while (try m1.step(&m2.queue) or try m2.step(&m1.queue)) {}

    return .{ mp1.queue.popBack(), m2.snd_count };
}

pub const solve = solver.intSolver(i64, solveInt);
