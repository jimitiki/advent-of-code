const std = @import("std");

const solver = @import("../solver.zig");
const Interpreter = @import("asm.zig").Interpreter;

const SignalChecker = struct {
    var expected: i64 = 0;
    var ok = true;

    pub fn checkSignal(signal: i64) void {
        if (!ok) return;
        if (signal != expected) {
            ok = false;
        } else {
            expected = if (expected == 0) 1 else 0;
        }
    }

    pub fn reset() void {
        expected = 0;
        ok = true;
    }
};

fn solveInt(tools: solver.Tools) solver.Error!struct { ?i64, ?i64 } {
    var interpreter: Interpreter = .init(SignalChecker.checkSignal);
    defer interpreter.unload(tools.gpa);
    const text = tools.input.reader.peekGreedy(1) catch unreachable;
    const p1: ?i64 = for (0..std.math.maxInt(i64)) |i| {
        try interpreter.load(tools.gpa, text);
        interpreter.setRegister(.a, @intCast(i));
        interpreter.executeUntil(9);
        while (interpreter.pc != 8 and SignalChecker.ok) interpreter.step();
        if (SignalChecker.ok) {
            break @intCast(i);
        } else {
            SignalChecker.reset();
        }
    } else null;
    return .{ p1, null };
}

pub const solve = solver.intSolver(i64, solveInt);
