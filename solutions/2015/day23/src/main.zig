const std = @import("std");

const lib = @import("lib");
const Boilerplate = lib.Boilerplate;
const WordIterator = lib.parse.WordIterator;

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

    fn parse(string: []const u8) Instruction {
        var it: WordIterator = .{ .string = string, .omit_punctuation = true };
        const op = std.meta.stringToEnum(Op, it.next().?).?;
        const arg1 = it.next().?;
        const arg2 = it.next();
        return switch (op) {
            .hlf => .{ .hlf = parseRegister(arg1) },
            .tpl => .{ .tpl = parseRegister(arg1) },
            .inc => .{ .inc = parseRegister(arg1) },
            .jmp => .{ .jmp = parseOffset(arg1) },
            .jie => .{ .jie = .{ parseRegister(arg1), parseOffset(arg2.?) } },
            .jio => .{ .jio = .{ parseRegister(arg1), parseOffset(arg2.?) } },
        };
    }

    fn parseOffset(string: []const u8) Offset {
        const sign: Sign = if (string[0] == '-') .neg else .pos;
        const absolute = std.fmt.parseUnsigned(usize, string[1..], 10) catch unreachable;
        return .{ sign, absolute };
    }

    fn parseRegister(string: []const u8) Register {
        return std.meta.stringToEnum(Register, string).?;
    }
};

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;
    var program: std.ArrayList(Instruction) = .empty;
    defer program.deinit(bp.arena);
    while (try input.takeDelimiter('\n')) |line| {
        try program.append(bp.arena, Instruction.parse(line));
    }
    var pc: usize = 0;
    var reg_a: u64 = 0;
    var reg_b: u64 = 0;
    while (pc < program.items.len) {
        switch (program.items[pc]) {
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

    // std.debug.print("{}\n", .{program});

    try stdout.print("REGISTER A: {} | REGISTER B: {}\n", .{ reg_a, reg_b });
    try stdout.flush();
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
