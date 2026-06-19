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
    var instruction_list: std.ArrayList(duet.Instruction) = .empty;
    defer instruction_list.deinit(tools.gpa);

    var reader = input.reader();
    while (try reader.takeDelimiter('\n')) |line| {
        try instruction_list.append(tools.gpa, try parseInstruction(line));
    }

    var mp1: duet.Interpreter = .init(0);
    defer mp1.deinit(gpa);
    mp1.load(instruction_list.items);
    while (try mp1.step(gpa, &mp1.queue)) {
        switch (mp1.program[mp1.pc]) {
            .rcv => break,
            else => {},
        }
    }

    var m1: duet.Interpreter = .init(0);
    defer m1.deinit(gpa);
    var m2: duet.Interpreter = .init(1);
    defer m2.deinit(gpa);
    m1.load(instruction_list.items);
    m2.load(instruction_list.items);
    while (try m1.step(gpa, &m2.queue) or try m2.step(gpa, &m1.queue)) {}

    return .{ mp1.queue.popBack(), m2.snd_count };
}

pub const solve = solver.intSolver(i64, solveInt);

fn value(reg: *const [26]i64, o: duet.Operand) i64 {
    return switch (o) {
        .r => |r| reg[r],
        .v => |v| v,
    };
}

fn parseInstruction(str: []const u8) Parser.Error!duet.Instruction {
    var parser: Parser = .init(str, .{});
    const opcode = try parser.takeEnum(duet.Opcode);
    return switch (opcode) {
        .add => .{ .add = .{ try parseOperand(&parser), try parseOperand(&parser) } },
        .jgz => .{ .jgz = .{ try parseOperand(&parser), try parseOperand(&parser) } },
        .mod => .{ .mod = .{ try parseOperand(&parser), try parseOperand(&parser) } },
        .mul => .{ .mul = .{ try parseOperand(&parser), try parseOperand(&parser) } },
        .rcv => .{ .rcv = try parseOperand(&parser) },
        .set => .{ .set = .{ try parseOperand(&parser), try parseOperand(&parser) } },
        .snd => .{ .snd = try parseOperand(&parser) },
    };
}

fn parseOperand(parser: *Parser) Parser.Error!duet.Operand {
    if (parser.takeEnum(duet.Register)) |r| {
        return .{ .r = r };
    } else |err| {
        return switch (err) {
            error.InvalidToken => .{ .v = try parser.takeInt(i64) },
            else => |e| e,
        };
    }
}
