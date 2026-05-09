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
        sum += try sumInvalidIds(range[0..split_point], range[split_point + 1 .. end], 2);
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

fn sumInvalidIds(first: []const u8, last: []const u8, seq_cnt: usize) !u64 {
    const min = try std.fmt.parseInt(u64, first, 10);
    const max = try std.fmt.parseInt(u64, last, 10);
    var sbuf: [16:0]u8 = .{0} ** 16;
    var cbuf: [32:0]u8 = .{0} ** 32;
    var seq: []u8 = undefined;
    if (first.len % seq_cnt == 0) {
        const len = @divExact(first.len, seq_cnt);
        @memcpy(sbuf[0..len], first[0..len]);
        seq = sbuf[0..len];
    } else {
        const digits: usize = @divTrunc(first.len, seq_cnt) + 1;
        sbuf[0] = '1';
        @memset(sbuf[1..digits], '0');
        seq = sbuf[0..digits];
    }
    var sum: u64 = 0;
    while (true) {
        for (0..seq_cnt) |i| {
            const buf_idx = i * seq.len;
            @memcpy(cbuf[buf_idx .. buf_idx + seq.len], seq);
        }
        const id_num = try std.fmt.parseInt(u64, cbuf[0 .. seq.len * seq_cnt], 10);
        if (id_num > max) {
            return sum;
        } else if (id_num >= min) {
            sum += id_num;
        }
        seq = try std.fmt.bufPrint(&sbuf, "{}", .{(try std.fmt.parseInt(u64, seq, 10)) + 1});
    }
}
