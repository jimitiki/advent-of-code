const std = @import("std");

const solver = @import("../solver.zig");
const WordIterator = @import("../parse.zig").WordIterator;

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

    fn parse(string: []const u8) error{InvalidInput}!Instruction {
        var it: WordIterator = .{ .string = string, .omit_punctuation = true };
        const opstr = it.next() orelse return error.InvalidInput;
        const op = std.meta.stringToEnum(Op, opstr) orelse return error.InvalidInput;
        const arg1 = it.next() orelse return error.InvalidInput;
        const arg2 = it.next();
        return switch (op) {
            .hlf => .{ .hlf = try parseRegister(arg1) },
            .tpl => .{ .tpl = try parseRegister(arg1) },
            .inc => .{ .inc = try parseRegister(arg1) },
            .jmp => .{ .jmp = try parseOffset(arg1) },
            .jie => .{ .jie = .{ try parseRegister(arg1), try parseOffset(arg2.?) } },
            .jio => .{ .jio = .{ try parseRegister(arg1), try parseOffset(arg2.?) } },
        };
    }

    fn parseOffset(string: []const u8) error{InvalidInput}!Offset {
        const sign: Sign = if (string[0] == '-') .neg else .pos;
        const absolute = std.fmt.parseUnsigned(usize, string[1..], 10) catch return error.InvalidInput;
        return .{ sign, absolute };
    }

    fn parseRegister(string: []const u8) error{InvalidInput}!Register {
        return std.meta.stringToEnum(Register, string) orelse error.InvalidInput;
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
