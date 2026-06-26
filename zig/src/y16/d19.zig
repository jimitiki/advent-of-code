const std = @import("std");
const lib = @import("lib");

const solver = lib.solver;

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    _ = tools;
    var parser = input.parser(.{});
    const elf_count = try parser.takeInt(u32);
    return .{ takeLeft(elf_count), takeAcross(elf_count) };
}

pub const solve = solver.intSolver(u32, solveInt);

fn takeLeft(elf_count: u32) u32 {
    var count = elf_count;
    var first_elf: u32 = 1;
    var factor: u32 = 2;
    while (count > 1) : ({
        count >>= 1;
        factor <<= 1;
    }) {
        if (count & 1 == 1) {
            first_elf += factor;
        }
    }
    return first_elf;
}

const Elf = struct {
    num: u32,
    prev: *Elf,
    next: *Elf,
};

fn takeAcross(elf_count: u32) u32 {
    var pow3_low: u32 = 1;
    var pow3_high: u32 = pow3_low * 3;
    while (pow3_high <= elf_count) : ({
        pow3_low = pow3_high;
        pow3_high = pow3_low * 3;
    }) {}

    if (elf_count == pow3_low) {
        return pow3_low;
    } else if (elf_count > pow3_low * 2) {
        return pow3_low + (elf_count - pow3_low * 2) * 2;
    } else {
        return elf_count - pow3_low;
    }
}
