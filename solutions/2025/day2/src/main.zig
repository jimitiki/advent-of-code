const std = @import("std");
const Io = std.Io;
const assert = std.debug.assert;
const lib = @import("boilerplate");
const AutoArrayHashMap = std.array_hash_map.Auto;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try lib.Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;
    var sum: u128 = 0;
    var invalid_ids: AutoArrayHashMap(u64, void) = .empty;
    while (try input.takeDelimiter(',')) |range| {
        var lengths: AutoArrayHashMap(usize, void) = .empty;
        defer lengths.deinit(bp.arena);
        const split_point = try find(range, '-');
        var end = range.len;
        while (range[end - 1] == '\n' or range[end - 1] == ' ') {
            end -= 1;
        }
        outer_loop: for (2..end - split_point + 1) |seq_len| {
            for (lengths.keys()) |l| {
                if (seq_len % l == 0) continue :outer_loop;
            }
            sum += try sumInvalidIds(range[0..split_point], range[split_point + 1 .. end], seq_len, &invalid_ids, bp.arena);
            try lengths.put(bp.arena, seq_len, {});
            if (bp.part == .p1) break;
        }
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

fn sumInvalidIds(
    first: []const u8,
    last: []const u8,
    seq_cnt: usize,
    invalid_ids: *AutoArrayHashMap(u64, void),
    alloc: std.mem.Allocator,
) !u64 {
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
        } else if (id_num >= min and !invalid_ids.contains(id_num)) {
            sum += id_num;
            try invalid_ids.put(alloc, id_num, {});
        }
        seq = try std.fmt.bufPrint(&sbuf, "{}", .{(try std.fmt.parseInt(u64, seq, 10)) + 1});
    }
}
