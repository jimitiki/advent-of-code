const std = @import("std");

pub const Register = enum { a, b, f, i, p };
pub const Opcode = enum { add, jgz, mod, mul, rcv, set, snd };
pub const Operand = union(enum) {
    r: Register,
    v: i64,
};
pub const Instruction = union(Opcode) {
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
