const std = @import("std");
const Io = std.Io;
const assert = std.debug.assert;
const lib = @import("lib");

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var ini = try lib.Init.init(init, &stdout_buffer, &read_buffer);
    defer ini.deinit();

    var stdout = &ini.stdout_writer.interface;
    var input = &ini.input_reader.interface;
    var sum: u128 = 0;
    while (try input.takeDelimiter(',')) |range| {
        const split_point = try find(range, '-');
        var end = range.len;
        while (range[end - 1] == '\n' or range[end - 1] == ' ') {
            end -= 1;
        }
        sum += try sumInvalidIds(range[0..split_point], range[split_point + 1 .. end]);
    }

    try stdout.print("{}\n", .{sum});
    try stdout.flush();
}

fn find(str: []const u8, char: u8) !usize {
    for (str, 0..) |c, i| {
        if (c == char) {
            return i;
        }
    }
    return error.NotFound;
}

fn sumInvalidIds(first: []const u8, last: []const u8) !u128 {
    const min = try std.fmt.parseInt(u64, first, 10);
    const max = try std.fmt.parseInt(u64, last, 10);
    var sbuf: [16:0]u8 = .{0} ** 16;
    var cbuf: [32:0]u8 = .{0} ** 32;
    var seq: []u8 = "";
    if (first.len % 2 == 0) {
        const len = @divExact(first.len, 2);
        @memcpy(sbuf[0..len], first[0..len]);
        seq = sbuf[0..len];
    } else {
        sbuf[0] = '1';
        if (first.len > 1) {
            @memset(sbuf[1 .. first.len - 1], '0');
            seq = sbuf[0 .. first.len - 1];
        } else {
            seq = sbuf[0..1];
        }
    }
    var sum: u128 = 0;
    while (true) {
        const candidate = try std.fmt.bufPrint(&cbuf, "{s}{s}", .{ seq, seq });
        const id_num = try std.fmt.parseInt(u64, candidate, 10);
        if (id_num > max) {
            return sum;
        } else if (id_num >= min) {
            sum += id_num;
        }
        seq = try std.fmt.bufPrint(&sbuf, "{}", .{(try std.fmt.parseInt(u64, seq, 10)) + 1});
    }
}
