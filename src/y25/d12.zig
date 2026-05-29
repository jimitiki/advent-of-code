const std = @import("std");

const solver = @import("../solver.zig");

const Shape = std.bit_set.IntegerBitSet(9);

// TODO: Fix computation of a definitely valid arrangement (needs to see if 3x3 will fit, not 1x9/9x1)

fn solveInt(gpa: std.mem.Allocator, input: *std.Io.Reader) solver.Error!struct { ?usize, ?usize } {
    var valid: usize = 0;
    var invalid: usize = 0;
    var unknown: usize = 0;
    var shape_mode = true;
    var counter: usize = 0;
    var shapes: std.ArrayList(Shape) = .empty;
    defer shapes.deinit(gpa);
    var shape: Shape = undefined;
    while (try input.takeDelimiter('\n')) |line| {
        if (shape_mode and line.len > 2 and line[2] == 'x') {
            shape_mode = false;
        }
        if (shape_mode) {
            if (line.len == 0) {
                try shapes.append(gpa, shape);
            } else if (line[1] == ':') {
                shape = .empty;
                counter = 0;
            } else {
                for (line) |c| {
                    if (c == '#') shape.set(counter);
                    counter += 1;
                }
            }
            continue;
        }

        const width = std.fmt.parseUnsigned(u16, line[0..2], 10) catch return error.InvalidInput;
        const height = std.fmt.parseUnsigned(u16, line[3..5], 10) catch return error.InvalidInput;
        const area = width * height;
        var counts: []u8 = try gpa.alloc(u8, shapes.items.len);
        defer gpa.free(counts);
        for (line[6..], 6..) |c, i| {
            if (c == ' ') {
                counts[@divExact(i - 6, 3)] = std.fmt.parseUnsigned(u8, line[i + 1 .. i + 3], 10) catch return error.InvalidInput;
            }
        }
        var worst_case: u16 = 0;
        var best_case: u16 = 0;
        for (counts, shapes.items) |count, s| {
            worst_case += @as(u16, count) * 9;
            best_case += @as(u16, count) * @as(u16, @intCast(s.count()));
        }
        if (worst_case < area) {
            valid += 1;
        } else if (best_case > area) {
            invalid += 1;
        } else {
            unknown += 1;
        }
    }
    return .{ valid + unknown, null };
}

pub const solve = solver.intSolver(usize, solveInt);
