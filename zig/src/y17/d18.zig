const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

// TODO: Use actual threading with a message queue
// TODO: Fix the behavior in part 1. It works for the real input, but the interpreter does not
//       behave as described in the problem spec. Perhaps there should be two modes, one where a
//       rcv with an empty queue skips to the next instruction, and one where it waits.

const Register = enum { a, b, f, i, p };
const Opcode = enum { add, jgz, mod, mul, rcv, set, snd };
const Operand = union(enum) {
    r: Register,
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

const Registers = std.EnumArray(Register, i64);
const Queue = std.Deque(i64);
const Interpreter = struct {
    const Self = @This();

    registers: Registers,
    pc: usize = 0,
    queue: Queue = .empty,
    program: []const Instruction = &.{},
    snd_count: u32 = 0,

    pub fn init(pid: u32) Self {
        var registers: Registers = .initFill(0);
        registers.set(.p, pid);
        return .{ .registers = registers };
    }

    pub fn deinit(self: *Self, gpa: std.mem.Allocator) void {
        self.queue.deinit(gpa);
    }

    pub fn load(self: *Self, program: []const Instruction) void {
        self.program = program;
    }

    pub fn step(self: *Self, gpa: std.mem.Allocator, qsnd: *Queue) error{OutOfMemory}!bool {
        if (self.pc >= self.program.len) return false;
        switch (self.program[self.pc]) {
            .add => |operands| {
                const r = operands[0].r;
                self.set(r, self.registers.get(r) + self.value(operands[1]));
            },
            .jgz => |operands| {
                if (self.value(operands[0]) > 0) {
                    const next = @as(i64, @intCast(self.pc)) + self.value(operands[1]);
                    if (next < 0) {
                        self.pc = self.program.len + 1;
                    } else {
                        self.pc = @intCast(next);
                    }

                    // Avoid incrementing the program counter.
                    return true;
                }
            },
            .mod => |operands| {
                const r = operands[0].r;
                self.set(r, @rem(self.registers.get(r), self.value(operands[1])));
            },
            .mul => |operands| {
                const r = operands[0].r;
                self.set(r, self.registers.get(r) * self.value(operands[1]));
            },
            .rcv => |operand| {
                if (self.queue.popFront()) |v| {
                    self.set(operand.r, v);
                } else return false;
            },
            .set => |operands| {
                const r = operands[0].r;
                self.set(r, self.value(operands[1]));
            },
            .snd => |operand| {
                try qsnd.pushBack(gpa, self.value(operand));
                self.snd_count += 1;
            },
        }
        self.pc += 1;
        return true;
    }

    fn value(self: Self, o: Operand) i64 {
        return switch (o) {
            .r => |r| self.registers.get(r),
            .v => |v| v,
        };
    }

    fn set(self: *Self, r: Register, v: i64) void {
        self.registers.set(r, v);
    }
};

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?i64, ?i64 } {
    const gpa = tools.gpa;
    var instruction_list: std.ArrayList(Instruction) = .empty;
    defer instruction_list.deinit(tools.gpa);

    var reader = input.reader();
    while (try reader.takeDelimiter('\n')) |line| {
        try instruction_list.append(tools.gpa, try parseInstruction(line));
    }

    var mp1: Interpreter = .init(0);
    defer mp1.deinit(gpa);
    mp1.load(instruction_list.items);
    while (try mp1.step(gpa, &mp1.queue)) {
        switch (mp1.program[mp1.pc]) {
            .rcv => break,
            else => {},
        }
    }

    var m1: Interpreter = .init(0);
    defer m1.deinit(gpa);
    var m2: Interpreter = .init(1);
    defer m2.deinit(gpa);
    m1.load(instruction_list.items);
    m2.load(instruction_list.items);
    while (try m1.step(gpa, &m2.queue) or try m2.step(gpa, &m1.queue)) {}

    return .{ mp1.queue.popBack(), m2.snd_count };
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
    if (parser.takeEnum(Register)) |r| {
        return .{ .r = r };
    } else |err| {
        return switch (err) {
            error.InvalidToken => .{ .v = try parser.takeInt(i64) },
            else => |e| e,
        };
    }
}
