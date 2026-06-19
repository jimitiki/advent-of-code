const std = @import("std");

const solver = @import("../solver.zig");

const Parser = @import("../Parser.zig");

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
pub const Interpreter = struct {
    const Self = @This();

    gpa: std.mem.Allocator,
    buf: [64]Instruction = undefined,
    registers: Registers,
    program: []const Instruction = undefined,
    pc: usize = 0,
    queue: Queue = .empty,
    snd_count: u32 = 0,

    pub fn init(gpa: std.mem.Allocator, pid: u32) Self {
        var registers: Registers = .initFill(0);
        registers.set(.p, pid);
        var interpreter: Self = .{ .gpa = gpa, .registers = registers };
        interpreter.program = interpreter.buf[0..0];
        return interpreter;
    }

    pub fn deinit(self: *Self) void {
        self.queue.deinit(self.gpa);
    }

    pub fn load(self: *Self, program: []const u8) Parser.Error!void {
        var lines: solver.Input.LineIterator = .{ .buf = program };
        var index: usize = 0;
        while (lines.next()) |line| {
            if (line.len > 0) {
                self.buf[index] = try parseInstruction(line);
                index += 1;
            }
        }
        self.program = self.buf[0..index];
    }

    pub fn step(self: *Self, qsnd: *Queue) error{OutOfMemory}!bool {
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
                try qsnd.pushBack(self.gpa, self.value(operand));
                self.snd_count += 1;
            },
        }
        self.pc += 1;
        return true;
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
