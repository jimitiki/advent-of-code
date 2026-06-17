const std = @import("std");
const solver = @import("../solver.zig");

const Box = struct { u32, u32, u32 };

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var answer1: u32 = 0;
    var answer2: u32 = 0;
    while (try tools.input.reader.takeDelimiter('\n')) |line| {
        const wstart = for (line, 0..) |c, i| {
            if (c == 'x') {
                break i + 1;
            }
        } else return error.InvalidInput;
        const hstart = for (line[wstart + 1 ..], wstart + 1..) |c, i| {
            if (c == 'x') {
                break i + 1;
            }
        } else return error.InvalidInput;
        const box: Box = .{
            std.fmt.parseUnsigned(u32, line[0 .. wstart - 1], 10) catch return error.InvalidInput,
            std.fmt.parseUnsigned(u32, line[wstart .. hstart - 1], 10) catch return error.InvalidInput,
            std.fmt.parseUnsigned(u32, line[hstart..], 10) catch return error.InvalidInput,
        };
        answer1 += wrappingPaper(box);
        answer2 += ribbon(box);
    }
    return .{ answer1, answer2 };
}

pub const solve = solver.intSolver(u32, solveInt);

fn wrappingPaper(box: Box) u32 {
    const area_lw = box[0] * box[1];
    const area_lh = box[0] * box[2];
    const area_wh = box[1] * box[2];
    const surface_area = area_lw * 2 + area_lh * 2 + area_wh * 2;
    return surface_area + @min(box[0] * box[1], box[0] * box[2], box[1] * box[2]);
}

fn ribbon(box: Box) u32 {
    const volume = box[0] * box[1] * box[2];
    return volume + @min(
        2 * box[0] + 2 * box[1],
        2 * box[0] + 2 * box[2],
        2 * box[1] + 2 * box[2],
    );
}
