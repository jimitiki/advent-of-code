const std = @import("std");

const solver = @import("../solver.zig");

const Opcode = enum { cpy, inc, dec, jnz };
const Operand = union(enum) { reg: u2, int: i64 };
const Instruction = union(Opcode) {
    cpy: struct { Operand, u2 },
    inc: u2,
    dec: u2,
    jnz: struct { Operand, i64 },
};

fn solveInt(tools: solver.Tools) solver.Error!struct { ?i64, ?i64 } {
    var program: std.ArrayList(Instruction) = .empty;
    defer program.deinit(tools.gpa);
    while (try tools.input.takeDelimiter('\n')) |line| {
        try program.append(tools.gpa, try parseInstruction(line));
    }
    var registers = [_]i64{0} ** 4;
    execute(&registers, program.items);
    const p1 = registers[0];
    registers = [_]i64{ 0, 0, 1, 0 };
    execute(&registers, program.items);
    return .{ p1, registers[0] };
}

pub const solve = solver.intSolver(i64, solveInt);

fn execute(registers: *[4]i64, program: []const Instruction) void {
    var pc: usize = 0;
    while (pc < program.len) {
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
                    pc = @intCast(std.math.add(i64, @intCast(pc), operands[1]) catch unreachable);
                } else {
                    pc += 1;
                }
            },
        }
    }
}

fn getValue(registers: *const [4]i64, operand: Operand) i64 {
    return switch (operand) {
        .int => |v| v,
        .reg => |r| registers[r],
    };
}

test "program" {
    const program: []const Instruction = &.{
        .{ .cpy = .{ .{ .int = 41 }, 0 } },
        .{ .inc = 0 },
        .{ .inc = 0 },
        .{ .dec = 0 },
        .{ .jnz = .{ .{ .reg = 0 }, 2 } },
        .{ .dec = 0 },
    };
    var registers = [_]i64{0} ** 4;
    execute(&registers, program);
    try std.testing.expectEqual(registers[0], 42);
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
                        std.fmt.parseInt(i64, str[i + 1 ..], 10) catch return error.InvalidInput,
                    } };
                }
            } else return error.InvalidInput;
        },
    }
}

fn parseOperand(str: []const u8) error{InvalidInput}!Operand {
    if (str.len == 1 and str[0] >= 'a' and str[0] <= 'd') {
        return .{ .reg = @intCast(str[0] - 'a') };
    } else {
        return .{ .int = std.fmt.parseUnsigned(i64, str, 10) catch return error.InvalidInput };
    }
}

test "parse" {
    try std.testing.expectEqual(
        Instruction{ .cpy = .{ .{ .int = 123 }, 0 } },
        parseInstruction("cpy 123 a"),
    );
    try std.testing.expectEqual(
        Instruction{ .jnz = .{ .{ .reg = 1 }, -3 } },
        parseInstruction("jnz b -3"),
    );
    try std.testing.expectEqual(
        Instruction{ .inc = 0 },
        parseInstruction("inc a"),
    );
    try std.testing.expectEqual(
        Instruction{ .dec = 3 },
        parseInstruction("dec d"),
    );
}
