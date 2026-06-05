const std = @import("std");

const solver = @import("../solver.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var elf_count = std.fmt.parseUnsigned(u32, try tools.takeOneLine(), 10) catch return error.InvalidInput;
    var first_elf: u32 = 1;
    var factor: u32 = 2;
    while (elf_count > 1) : ({
        elf_count >>= 1;
        factor <<= 1;
    }) {
        if (elf_count & 1 == 1) {
            first_elf += factor;
        }
    }
    return .{ first_elf, null };
}

pub const solve = solver.intSolver(u32, solveInt);
