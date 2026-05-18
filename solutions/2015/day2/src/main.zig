const std = @import("std");

const Boilerplate = @import("boilerplate").Boilerplate;

const Box = struct { u32, u32, u32 };

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;
    var answer: u32 = 0;
    const compute: *const fn (Box) u32 = switch (bp.part) {
        .p1 => wrappingPaper,
        .p2 => ribbon,
    };
    while (try input.takeDelimiter('\n')) |line| {
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
            try std.fmt.parseUnsigned(u32, line[0 .. wstart - 1], 10),
            try std.fmt.parseUnsigned(u32, line[wstart .. hstart - 1], 10),
            try std.fmt.parseUnsigned(u32, line[hstart..], 10),
        };
        answer += compute(box);
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

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
