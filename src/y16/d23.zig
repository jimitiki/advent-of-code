const std = @import("std");

const solver = @import("../solver.zig");

const Opcode = enum { cpy, inc, dec, jnz, tgl, nop };
const Operand = union(enum) { reg: u2, int: i64 };
const Instruction = union(Opcode) {
    cpy: struct { Operand, u2 },
    inc: u2,
    dec: u2,
    jnz: struct { Operand, Operand },
    tgl: Operand,
    nop: void,
};

// TODO: Speed up part 2

fn solveInt(tools: solver.Tools) solver.Error!struct { ?i64, ?i64 } {
    var program1: std.ArrayList(Instruction) = .empty;
    defer program1.deinit(tools.gpa);
    while (try tools.input.takeDelimiter('\n')) |line| {
        try program1.append(tools.gpa, try parseInstruction(line));
    }
    var program2 = try program1.clone(tools.gpa);
    defer program2.deinit(tools.gpa);

    var registers = [_]i64{ 7, 0, 0, 0 };
    execute(&registers, program1.items);
    const p1 = registers[0];
    registers = [_]i64{ 12, 0, 0, 0 };
    execute(&registers, program2.items);
    return .{ p1, registers[0] };
}

pub const solve = solver.intSolver(i64, solveInt);

fn execute(registers: *[4]i64, program: []Instruction) void {
    var pc: usize = 0;
    var i: u64 = 0;
    while (pc < program.len) : (i += 1) {
        const instruction = program[pc];
        switch (instruction) {
            .cpy => |operands| {
                registers[operands[1]] = getValue(registers, operands[0]);
                pc += 1;
            },
            .inc => |r| {
                registers[r] += 1;
                pc += 1;
            },
            .dec => |r| {
                registers[r] -= 1;
                pc += 1;
            },
            .jnz => |operands| {
                if (getValue(registers, operands[0]) != 0) {
                    pc = @intCast(std.math.add(i64, @intCast(pc), getValue(registers, operands[1])) catch unreachable);
                } else {
                    pc += 1;
                }
            },
            .nop => pc += 1,
            .tgl => |operand| {
                const idx: usize = @intCast(getValue(registers, operand) + @as(i64, @intCast(pc)));
                if (idx > 0 and idx < program.len) {
                    const real_idx: usize = @intCast(idx);
                    program[real_idx] = toggleInstruction(program[real_idx]);
                }
                pc += 1;
            },
        }
    }
}

fn toggleInstruction(inst: Instruction) Instruction {
    return switch (inst) {
        .inc => |r| .{ .dec = r },
        .dec => |r| .{ .inc = r },
        .tgl => |operand| switch (operand) {
            .reg => |r| .{ .inc = r },
            .int => .{ .nop = {} },
        },
        .cpy => |operands| .{ .jnz = .{ operands[0], .{ .reg = operands[1] } } },
        .jnz => |operands| switch (operands[1]) {
            .reg => |r| .{ .cpy = .{ operands[0], r } },
            .int => .{ .nop = {} },
        },
        .nop => @panic("Can't toggle noop"),
    };
}

fn getValue(registers: *const [4]i64, operand: Operand) i64 {
    return switch (operand) {
        .int => |v| v,
        .reg => |r| registers[r],
    };
}

fn parseInstruction(str: []const u8) error{InvalidInput}!Instruction {
    switch (std.meta.stringToEnum(Opcode, str[0..3]) orelse return error.InvalidInput) {
        .cpy => return .{ .cpy = .{
            try parseOperand(str[4 .. str.len - 2]),
            @intCast(str[str.len - 1] - 'a'),
        } },
        .inc => return .{ .inc = @intCast(str[str.len - 1] - 'a') },
        .dec => return .{ .dec = @intCast(str[str.len - 1] - 'a') },
        .jnz => {
            for (str[4..], 4..) |char, i| {
                if (char == ' ') {
                    return .{ .jnz = .{
                        try parseOperand(str[4..i]),
                        try parseOperand(str[i + 1 ..]),
                    } };
                }
            } else return error.InvalidInput;
        },
        .tgl => {
            return .{ .tgl = try parseOperand(str[4..]) };
        },
        .nop => unreachable,
    }
}

fn parseOperand(str: []const u8) error{InvalidInput}!Operand {
    if (str.len == 1 and str[0] >= 'a' and str[0] <= 'd') {
        return .{ .reg = @intCast(str[0] - 'a') };
    } else {
        return .{ .int = std.fmt.parseInt(i64, str, 10) catch return error.InvalidInput };
    }
}
