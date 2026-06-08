const std = @import("std");

const solver = @import("../solver.zig");
const Interpreter = @import("asm.zig").Interpreter;

const SignalChecker = struct {
    var expected: i64 = 0;
    var count: usize = 0;
    var ok = true;

    pub fn checkSignal(signal: i64) void {
        if (!ok) return;
        if (signal != expected) {
            ok = false;
        } else {
            count += 1;
            expected = if (expected == 0) 1 else 0;
        }
    }

    pub fn reset() void {
        expected = 0;
        count = 0;
        ok = true;
    }

    pub fn complete() bool {
        return !ok or count >= 16;
    }

    pub fn valid() bool {
        return count >= 16 and ok;
    }

    pub fn isInvalid() bool {
        return !ok;
    }
};

fn solveInt(tools: solver.Tools) solver.Error!struct { ?i64, ?i64 } {
    var interpreter: Interpreter = .init(SignalChecker.checkSignal);
    defer interpreter.unload(tools.gpa);
    const text = tools.input.peekGreedy(1) catch unreachable;
    const p1: ?i64 = for (0..std.math.maxInt(i64)) |i| {
        try interpreter.load(tools.gpa, text);
        interpreter.setRegister(.a, @intCast(i));
        while (!SignalChecker.complete()) interpreter.step();
        if (SignalChecker.valid()) break @intCast(i);
        SignalChecker.reset();
    } else null;
    return .{ p1, null };
}

pub const solve = solver.intSolver(i64, solveInt);
