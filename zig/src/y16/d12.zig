const std = @import("std");

const solver = @import("../solver.zig");
const Interpreter = @import("asm.zig").Interpreter;

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?i64, ?i64 } {
    var interpreter: Interpreter = .init(null);
    try interpreter.load(tools.gpa, input.text);
    defer interpreter.unload(tools.gpa);
    interpreter.execute();
    const p1 = interpreter.getRegister(.a);

    try interpreter.load(tools.gpa, input.text);
    interpreter.setRegister(.c, 1);
    interpreter.execute();
    const p2 = interpreter.getRegister(.a);
    return .{ p1, p2 };
}

pub const solve = solver.intSolver(i64, solveInt);
