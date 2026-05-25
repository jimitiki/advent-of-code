const std = @import("std");

const Boilerplate = @import("lib").Boilerplate;
const Shape = std.bit_set.IntegerBitSet(9);

// TODO: Fix known-good computation (needs to see if 3x3 will fit, not, say, 1x9)

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;

    var valid: usize = 0;
    var invalid: usize = 0;
    var unknown: usize = 0;
    var shape_mode = true;
    var counter: usize = 0;
    var shapes: std.ArrayList(Shape) = .empty;
    defer shapes.deinit(bp.arena);
    var shape: Shape = undefined;
    while (try input.takeDelimiter('\n')) |line| {
        if (shape_mode and line.len > 2 and line[2] == 'x') {
            shape_mode = false;
        }
        if (shape_mode) {
            if (line.len == 0) {
                try shapes.append(bp.arena, shape);
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

        const width = try std.fmt.parseUnsigned(u16, line[0..2], 10);
        const height = try std.fmt.parseUnsigned(u16, line[3..5], 10);
        const area = width * height;
        var counts: []u8 = try bp.arena.alloc(u8, shapes.items.len);
        defer bp.arena.free(counts);
        for (line[6..], 6..) |c, i| {
            if (c == ' ') {
                counts[@divExact(i - 6, 3)] = try std.fmt.parseUnsigned(u8, line[i + 1 .. i + 3], 10);
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

    try stdout.print("Known good: {} | Known bad: {} | Unknown: {}\n", .{ valid, invalid, unknown });
    try stdout.print("Answer maybe equals: {}\n", .{valid + unknown});
    try stdout.flush();
}
