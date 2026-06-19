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

    var m1: duet.Interpreter = .init(gpa, 0);
    defer m1.deinit();
    try m1.load(input.text);
    while (try m1.step(&m1.queue)) {
        switch (m1.program[m1.pc]) {
            .rcv => break,
            else => {},
        }
    }
    const recovered_frequency = m1.queue.popBack();

    var m2: duet.Interpreter = .init(gpa, 1);
    defer m2.deinit();
    try m1.load(input.text);
    try m2.load(input.text);
    while (try m1.step(&m2.queue) or try m2.step(&m1.queue)) {}

    return .{ recovered_frequency, m2.snd_count };
}

pub const solve = solver.intSolver(i64, solveInt);
