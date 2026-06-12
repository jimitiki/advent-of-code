const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

const Opcode = enum { add, jgz, mod, mul, rcv, set, snd };
const Operand = union(enum) {
    r: u8,
    v: i64,
};
const Instruction = union(Opcode) {
    add: struct { Operand, Operand },
    jgz: struct { Operand, Operand },
    mod: struct { Operand, Operand },
    mul: struct { Operand, Operand },
    rcv: Operand,
    set: struct { Operand, Operand },
    snd: Operand,
};

fn solveInt(tools: solver.Tools) solver.Error!struct { ?i64, ?i64 } {
    var instruction_list: std.ArrayList(Instruction) = .empty;
    defer instruction_list.deinit(tools.gpa);

    while (try tools.input.takeDelimiter('\n')) |line| {
        try instruction_list.append(tools.gpa, try parseInstruction(line));
    }

    var reg: [26]i64 = .{0} ** 26;
    var pc: usize = 0;
    var p1: ?i64 = null;
    var sound: i64 = 0;
    while (pc < instruction_list.items.len) {
        switch (instruction_list.items[pc]) {
            .add => |operands| {
                reg[operands[0].r] += value(&reg, operands[1]);
                pc += 1;
            },
            .jgz => |operands| {
                if (value(&reg, operands[0]) > 0) {
                    const next = @as(i64, @intCast(pc)) + value(&reg, operands[1]);
                    if (next < 0) break;
                    pc = @intCast(next);
                } else pc += 1;
            },
            .mod => |operands| {
                const reg_idx = operands[0].r;
                reg[reg_idx] = @rem(reg[reg_idx], value(&reg, operands[1]));
                pc += 1;
            },
            .mul => |operands| {
                reg[operands[0].r] *= value(&reg, operands[1]);
                pc += 1;
            },
            .rcv => |operand| {
                if (value(&reg, operand) != 0) {
                    p1 = sound;
                    break;
                }
                pc += 1;
            },
            .set => |operands| {
                reg[operands[0].r] = value(&reg, operands[1]);
                pc += 1;
            },
            .snd => |operand| {
                sound = value(&reg, operand);
                pc += 1;
            },
        }
    }
    return .{ p1, null };
}

pub const solve = solver.intSolver(i64, solveInt);

fn value(reg: *const [26]i64, o: Operand) i64 {
    return switch (o) {
        .r => |r| reg[r],
        .v => |v| v,
    };
}

fn parseInstruction(str: []const u8) Parser.Error!Instruction {
    var parser: Parser = .init(str, .{});
    const opcode = try parser.takeEnum(Opcode);
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

fn parseOperand(parser: *Parser) Parser.Error!Operand {
    if (parser.takeInt(i64)) |v| {
        return .{ .v = v };
    } else |err| {
        return switch (err) {
            error.InvalidToken => .{ .r = try parser.takeByte() - 97 },
            else => |e| e,
        };
    }
}
