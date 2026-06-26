const std = @import("std");
const Allocator = std.mem.Allocator;

const Parser = @import("lib").Parser;

const Opcode = enum { cpy, dec, inc, jnz, out, tgl };
pub const Register = enum(u2) { a = 0, b = 1, c = 2, d = 3 };
const Operand = union(enum) {
    register: Register,
    integer: i64,
};
const Instruction = union(Opcode) {
    cpy: struct { Operand, Operand },
    dec: Operand,
    inc: Operand,
    jnz: struct { Operand, Operand },
    out: Operand,
    tgl: Operand,
};
const SignalFn = fn (signal: i64) void;
fn signalNoop(_: i64) void {}

pub const Interpreter = struct {
    const Self = @This();

    registers: [4]i64,
    program: []Instruction,
    signal: *const SignalFn,
    pc: usize = 0,
    loaded: bool = false,

    const LoadError = Parser.Error || Allocator.Error;

    pub fn init(signal: ?SignalFn) Self {
        return .{
            .registers = [_]i64{ 0, 0, 0, 0 },
            .program = undefined,
            .signal = if (signal) |s| s else signalNoop,
        };
    }

    pub fn load(self: *Self, gpa: std.mem.Allocator, text: []const u8) LoadError!void {
        var line_count: usize = 0;
        var reader = std.Io.Reader.fixed(text);
        while (reader.takeDelimiter('\n') catch unreachable) |line| {
            for (line) |char| {
                if (char == ' ' or char == '\t') continue;
                if (char != '#') line_count += 1;
                break;
            }
        }
        var program = try gpa.alloc(Instruction, line_count);

        reader.seek = 0;
        var i: usize = 0;
        while (reader.takeDelimiter('\n') catch unreachable) |line| : (i += 1) {
            if (line.len > 0 and line[0] == '#') continue;
            program[i] = try parseInstruction(line);
        }

        if (self.loaded) gpa.free(self.program);
        self.program = program;
        self.loaded = true;
        self.pc = 0;
        self.registers = [_]i64{ 0, 0, 0, 0 };
    }

    pub fn unload(self: *Self, gpa: std.mem.Allocator) void {
        if (self.loaded) {
            gpa.free(self.program);
            self.loaded = false;
        }
    }

    fn parseInstruction(str: []const u8) Parser.Error!Instruction {
        var parser: Parser = .init(str, .{});
        return switch (try parser.takeEnum(Opcode)) {
            .cpy => .{ .cpy = .{ try parseOperand(&parser), try parseOperand(&parser) } },
            .dec => .{ .dec = try parseOperand(&parser) },
            .inc => .{ .inc = try parseOperand(&parser) },
            .jnz => .{ .jnz = .{ try parseOperand(&parser), try parseOperand(&parser) } },
            .tgl => .{ .tgl = try parseOperand(&parser) },
            .out => .{ .out = try parseOperand(&parser) },
        };
    }

    fn parseOperand(parser: *Parser) Parser.Error!Operand {
        if (parser.takeEnum(Register)) |r| {
            return .{ .register = r };
        } else |err| {
            switch (err) {
                error.InvalidToken => return .{ .integer = try parser.takeInt(i64) },
                else => return err,
            }
        }
    }

    pub fn setRegister(self: *Self, register: Register, value: i64) void {
        self.registers[@intFromEnum(register)] = value;
    }

    pub fn getRegister(self: Self, register: Register) i64 {
        return self.registers[@intFromEnum(register)];
    }

    fn getOperand(self: Self, operand: Operand) i64 {
        return switch (operand) {
            .register => |register| self.getRegister(register),
            .integer => |int| int,
        };
    }

    fn getOffset(self: Self, operand: Operand) usize {
        return @intCast(self.getOperand(operand) + @as(i64, @intCast(self.pc)));
    }

    fn setOperand(self: *Self, operand: Operand, value: i64) void {
        switch (operand) {
            .register => |register| self.setRegister(register, value),
            .integer => {},
        }
    }

    pub fn execute(self: *Self) void {
        if (!self.loaded) return;
        while (self.pc < self.program.len) {
            self.step();
        }
    }

    pub fn executeUntil(self: *Self, n: usize) void {
        if (!self.loaded) return;
        if (self.pc >= self.program.len) return;
        while (self.pc != n and self.pc < self.program.len) {
            self.step();
        }
    }

    pub fn step(self: *Self) void {
        const instruction = self.program[self.pc];
        switch (instruction) {
            .cpy => |operands| {
                self.setOperand(operands[1], self.getOperand(operands[0]));
                self.pc += 1;
            },
            .dec => |operand| {
                switch (operand) {
                    .register => |register| self.registers[@intFromEnum(register)] -= 1,
                    else => {},
                }
                self.pc += 1;
            },
            .inc => |operand| {
                switch (operand) {
                    .register => |register| self.registers[@intFromEnum(register)] += 1,
                    else => {},
                }
                self.pc += 1;
            },
            .jnz => |operands| {
                if (self.getOperand(operands[0]) != 0) {
                    self.pc = self.getOffset(operands[1]);
                } else {
                    self.pc += 1;
                }
            },
            .out => |operand| {
                self.pc += 1;
                self.signal(self.getOperand(operand));
            },
            .tgl => |operand| {
                const idx: usize = self.getOffset(operand);
                if (idx > 0 and idx < self.program.len) {
                    self.program[idx] = switch (self.program[idx]) {
                        .tgl, .dec, .out => |op| .{ .inc = op },
                        .inc => |op| .{ .dec = op },
                        .cpy => |ops| .{ .jnz = ops },
                        .jnz => |ops| .{ .cpy = ops },
                    };
                }
                self.pc += 1;
            },
        }
    }
};

test "program" {
    var interpreter: Interpreter = .init(null);
    defer interpreter.unload(std.testing.allocator);
    try interpreter.load(std.testing.allocator,
        \\ cpy 41 a
        \\ inc a
        \\ inc a
        \\ dec a
        \\ jnz a 2
        \\ dec a
    );
    interpreter.execute();
    try std.testing.expectEqual(42, interpreter.getRegister(.a));

    try interpreter.load(std.testing.allocator,
        \\ cpy 2 a
        \\ tgl a
        \\ tgl a
        \\ tgl a
        \\ cpy 1 a
        \\ dec a
        \\ dec a
    );
    interpreter.execute();
    try std.testing.expectEqual(3, interpreter.getRegister(.a));
}
