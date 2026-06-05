const std = @import("std");

const solver = @import("../solver.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    const elf_count = std.fmt.parseUnsigned(u32, try tools.takeOneLine(), 10) catch return error.InvalidInput;
    return .{ takeLeft(elf_count), try takeAcross(tools.gpa, elf_count) };
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

fn takeAcross(gpa: std.mem.Allocator, elf_count: u32) error{OutOfMemory}!u32 {
    const elves = try gpa.alloc(Elf, elf_count);
    defer gpa.free(elves);
    for (elves, 0..) |*elf, i| {
        elf.num = @intCast(i + 1);
        elf.prev = &elves[(i + elf_count - 1) % elf_count];
        elf.next = &elves[(i + 1) % elf_count];
    }
    var target = &elves[elf_count / 2];
    var left = elf_count;
    while (left > 1) : (left -= 1) {
        target.prev.next = target.next;
        target.next.prev = target.prev;
        if (left & 1 == 0) {
            target = target.next;
        } else {
            target = target.next.next;
        }
    }
    return target.num;
}
