const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

const Op = enum {
    hlf,
    tpl,
    inc,
    jmp,
    jie,
    jio,
};

const Register = enum { a, b };

const Sign = enum { pos, neg };
const Offset = struct { Sign, usize };

const Instruction = union(Op) {
    hlf: Register,
    tpl: Register,
    inc: Register,
    jmp: Offset,
    jie: struct { Register, Offset },
    jio: struct { Register, Offset },

    fn parse(string: []const u8) Parser.Error!Instruction {
        var parser: Parser = .init(string, .{});
        const op = try parser.takeEnum(Op);
        return switch (op) {
            .hlf => .{ .hlf = try parser.takeEnum(Register) },
            .tpl => .{ .tpl = try parser.takeEnum(Register) },
            .inc => .{ .inc = try parser.takeEnum(Register) },
            .jmp => .{ .jmp = try parseOffset(&parser) },
            .jie => .{ .jie = .{ try parser.takeEnum(Register), try parseOffset(&parser) } },
            .jio => .{ .jio = .{ try parser.takeEnum(Register), try parseOffset(&parser) } },
        };
    }

    fn parseOffset(parser: *Parser) Parser.Error!Offset {
        const offset = try parser.takeInt(isize);
        const sign: Sign = if (offset > 0) .pos else .neg;
        return .{ sign, @abs(offset) };
    }
};

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u64, ?u64 } {
    var program: std.ArrayList(Instruction) = .empty;
    defer program.deinit(tools.gpa);
    while (try tools.input.takeDelimiter('\n')) |line| {
        program.append(tools.gpa, try Instruction.parse(line)) catch unreachable;
    }
    return .{ execute(program.items, 0, 0), execute(program.items, 1, 0) };
}

pub const solve = solver.intSolver(u64, solveInt);

fn execute(program: []const Instruction, a: u64, b: u64) u64 {
    var reg_a = a;
    var reg_b = b;
    var pc: usize = 0;
    while (pc < program.len) {
        switch (program[pc]) {
            .hlf => |reg| {
                getRegister(&reg_a, &reg_b, reg).* /= 2;
                pc += 1;
            },
            .tpl => |reg| {
                getRegister(&reg_a, &reg_b, reg).* *= 3;
                pc += 1;
            },
            .inc => |reg| {
                getRegister(&reg_a, &reg_b, reg).* += 1;
                pc += 1;
            },
            .jmp => |offset| pc = jump(pc, offset),
            .jie => |args| {
                if (getRegister(&reg_a, &reg_b, args[0]).* % 2 == 0) {
                    pc = jump(pc, args[1]);
                } else {
                    pc += 1;
                }
            },
            .jio => |args| {
                if (getRegister(&reg_a, &reg_b, args[0]).* == 1) {
                    pc = jump(pc, args[1]);
                } else {
                    pc += 1;
                }
            },
        }
    }
    return reg_b;
}

fn getRegister(a: *u64, b: *u64, tag: Register) *u64 {
    return switch (tag) {
        .a => a,
        .b => b,
    };
}

fn jump(pc: usize, offset: Offset) usize {
    return switch (offset[0]) {
        .pos => pc + offset[1],
        .neg => pc - offset[1],
    };
}
