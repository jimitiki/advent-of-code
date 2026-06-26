const std = @import("std");
const lib = @import("lib");

const solver = lib.solver;

const Shape = std.bit_set.IntegerBitSet(9);

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?usize, ?usize } {
    var valid: usize = 0;
    var invalid: usize = 0;
    var unknown: usize = 0;
    var shape_mode = true;
    var counter: usize = 0;
    var shapes: std.ArrayList(Shape) = .empty;
    defer shapes.deinit(tools.gpa);
    var shape: Shape = undefined;
    var reader = input.reader();
    while (try reader.takeDelimiter('\n')) |line| {
        if (shape_mode and line.len > 2 and line[2] == 'x') {
            shape_mode = false;
        }
        if (shape_mode) {
            if (line.len == 0) {
                try shapes.append(tools.gpa, shape);
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
        var counts: []u8 = try tools.gpa.alloc(u8, shapes.items.len);
        defer tools.gpa.free(counts);
        for (line[6..], 6..) |c, i| {
            if (c == ' ') {
                counts[@divExact(i - 6, 3)] = std.fmt.parseUnsigned(u8, line[i + 1 .. i + 3], 10) catch return error.InvalidInput;
            }
        }
        var sum: u16 = 0;
        var best_case: u16 = 0;
        for (counts, shapes.items) |count, s| {
            best_case += @as(u16, count) * @as(u16, @intCast(s.count()));
            sum += count;
        }
        if (sum <= (width / 3) * (height / 3)) {
            valid += 1;
        } else if (best_case > area) {
            invalid += 1;
        } else {
            unknown += 1;
        }
    }
    return .{ if (unknown > 0) null else valid, null };
}

pub const solve = solver.intSolver(usize, solveInt);
