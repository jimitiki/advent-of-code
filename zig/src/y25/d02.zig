const std = @import("std");
const Io = std.Io;
const assert = std.debug.assert;
const AutoArrayHashMap = std.array_hash_map.Auto;

const solver = @import("../solver.zig");

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u64, ?u64 } {
    var answer1: u64 = 0;
    var answer2: u64 = 0;
    var invalid_ids: AutoArrayHashMap(u64, void) = .empty;
    defer invalid_ids.deinit(tools.gpa);
    var reader = input.reader();
    while (try reader.takeDelimiter(',')) |range| {
        var lengths: AutoArrayHashMap(usize, void) = .empty;
        defer lengths.deinit(tools.gpa);
        const split_point = find(range, '-') orelse return error.InvalidInput;
        var end = range.len;
        while (range[end - 1] == '\n' or range[end - 1] == ' ') {
            end -= 1;
        }
        outer_loop: for (2..end - split_point + 1) |seq_len| {
            for (lengths.keys()) |l| {
                if (seq_len % l == 0) continue :outer_loop;
            }
            const sum = try sumInvalidIds(range[0..split_point], range[split_point + 1 .. end], seq_len, &invalid_ids, tools.gpa);
            answer2 += sum;
            if (seq_len == 2) {
                answer1 += sum;
            }
            lengths.put(tools.gpa, seq_len, {}) catch unreachable;
        }
    }
    return .{ answer1, answer2 };
}

pub const solve = solver.intSolver(u64, solveInt);

fn find(str: []const u8, char: u8) ?usize {
    for (str, 0..) |c, i| {
        if (c == char) {
            return i;
        }
    }
    return null;
}

fn sumInvalidIds(
    first: []const u8,
    last: []const u8,
    seq_cnt: usize,
    invalid_ids: *AutoArrayHashMap(u64, void),
    alloc: std.mem.Allocator,
) error{InvalidInput}!u64 {
    const min = std.fmt.parseInt(u64, first, 10) catch return error.InvalidInput;
    const max = std.fmt.parseInt(u64, last, 10) catch return error.InvalidInput;
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
        const id_num = std.fmt.parseInt(u64, cbuf[0 .. seq.len * seq_cnt], 10) catch return error.InvalidInput;
        if (id_num > max) {
            return sum;
        } else if (id_num >= min and !invalid_ids.contains(id_num)) {
            sum += id_num;
            invalid_ids.put(alloc, id_num, {}) catch unreachable;
        }
        const int_seq = std.fmt.parseInt(u64, seq, 10) catch unreachable;
        seq = std.fmt.bufPrint(&sbuf, "{}", .{int_seq + 1}) catch unreachable;
    }
}
