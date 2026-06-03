const std = @import("std");

const solver = @import("../solver.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?usize, ?usize } {
    const len_v1, const len_v2 = try computeDecompressedLength(tools.input, std.math.maxInt(usize));
    return .{ len_v1, len_v2 };
}

pub const solve = solver.intSolver(usize, solveInt);

fn computeDecompressedLength(input: *std.Io.Reader, limit: usize) solver.Error!struct { usize, usize } {
    var len_v1: usize = 0;
    var len_v2: usize = 0;
    var actual_len: usize = 0;
    while (actual_len < limit) {
        if (input.takeByte()) |char| {
            if (char == '\n' or char == ' ') {
                continue;
            } else if (char == '(') {
                const char_cnt, const multiplier, const marker_len = try consumeMarker(input);
                actual_len += marker_len;
                _, const sublen_v2 = try computeDecompressedLength(input, char_cnt);
                actual_len += char_cnt;
                len_v1 += char_cnt * multiplier;
                len_v2 += sublen_v2 * multiplier;
            } else {
                actual_len += 1;
                len_v1 += 1;
                len_v2 += 1;
            }
        } else |_| break;
    }
    return .{ len_v1, len_v2 };
}

fn consumeMarker(input: *std.Io.Reader) solver.Error!struct { usize, usize, usize } {
    var len: usize = 3;
    const cnt_result = try consumeInt(input, 'x');
    len += cnt_result[1];
    const mult_result = try consumeInt(input, ')');
    len += mult_result[1];
    return .{ cnt_result[0], mult_result[0], len };
}

fn consumeInt(input: *std.Io.Reader, delimiter: u8) solver.Error!struct { usize, usize } {
    var buf: [8]u8 = undefined;
    var i: usize = 0;
    while (true) : (i += 1) {
        std.debug.assert(i < buf.len);
        const char = input.takeByte() catch return error.InvalidInput;
        if (char >= '0' and char <= '9') {
            buf[i] = char;
        } else if (char == delimiter) {
            return .{ std.fmt.parseInt(usize, buf[0..i], 10) catch unreachable, i };
        } else {
            return error.InvalidInput;
        }
    }
}

test "decompressed length" {
    {
        var reader = std.Io.Reader.fixed("ADVENT");
        try std.testing.expectEqual(.{ 6, 6 }, computeDecompressedLength(&reader, std.math.maxInt(usize)));
    }
    {
        var reader = std.Io.Reader.fixed("A(1x5)BC");
        try std.testing.expectEqual(.{ 7, 7 }, computeDecompressedLength(&reader, std.math.maxInt(usize)));
    }
    {
        var reader = std.Io.Reader.fixed("(3x3)XYZ");
        try std.testing.expectEqual(.{ 9, 9 }, computeDecompressedLength(&reader, std.math.maxInt(usize)));
    }
    {
        var reader = std.Io.Reader.fixed("A(2x2)BCD(2x2)EFG");
        try std.testing.expectEqual(.{ 11, 11 }, computeDecompressedLength(&reader, std.math.maxInt(usize)));
    }
    {
        var reader = std.Io.Reader.fixed("(6x1)(1x3)A");
        try std.testing.expectEqual(.{ 6, 3 }, computeDecompressedLength(&reader, std.math.maxInt(usize)));
    }
    {
        var reader = std.Io.Reader.fixed("X(8x2)(3x3)ABCY");
        try std.testing.expectEqual(.{ 18, 20 }, computeDecompressedLength(&reader, std.math.maxInt(usize)));
    }
    {
        var reader = std.Io.Reader.fixed("(27x12)(20x12)(13x14)(7x10)(1x12)A");
        try std.testing.expectEqual(.{ 324, 241920 }, computeDecompressedLength(&reader, std.math.maxInt(usize)));
    }
    {
        var reader = std.Io.Reader.fixed("(25x3)(3x3)ABC(2x3)XY(5x2)PQRSTX(18x9)(3x2)TWO(5x7)SEVEN");
        try std.testing.expectEqual(.{ 238, 445 }, computeDecompressedLength(&reader, std.math.maxInt(usize)));
    }
}
