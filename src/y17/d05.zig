const std = @import("std");

const solver = @import("../solver.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var offsets: std.ArrayList(i16) = .empty;
    defer offsets.deinit(tools.gpa);
    while (try tools.input.reader.takeDelimiter('\n')) |line| {
        try offsets.append(tools.gpa, std.fmt.parseInt(i16, line, 10) catch return error.InvalidInput);
    }
    const copy = try tools.gpa.alloc(i16, offsets.items.len);
    defer tools.gpa.free(copy);
    @memcpy(copy, offsets.items);
    return .{ countJumps(offsets.items, false), countJumps(copy, true) };
}

fn countJumps(offsets: []i16, dec_three: bool) u32 {
    var pc: u32 = 0;
    var jumps: u32 = 0;
    while (pc < offsets.len) : (jumps += 1) {
        const offset = offsets[pc];
        offsets[pc] += if (dec_three and offset >= 3) -1 else 1;
        pc = @intCast(@as(i32, @intCast(pc)) + offset);
    }
    return jumps;
}

pub const solve = solver.intSolver(u32, solveInt);
