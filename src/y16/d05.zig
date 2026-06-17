const std = @import("std");
const Md5 = std.crypto.hash.Md5;

const solver = @import("../solver.zig");
const hashIndex = @import("../hash.zig").hashIndex;

pub fn solve(tools: solver.Tools) solver.Error!struct { ?[]const u8, ?[]const u8 } {
    const stdout = tools.stdout;
    const seed = tools.input.reader.peekDelimiterExclusive('\n') catch return error.InvalidInput;
    var pw1: []u8 = tools.p1buf[0..8];
    @memset(pw1, '*');
    var pw1_cnt: u4 = 0;

    var pw2: []u8 = tools.p2buf[0..8];
    @memset(pw2, '*');
    var pw2_cnt: u4 = 0;

    var input_buf: [128]u8 = undefined;
    for (0..std.math.maxInt(usize)) |i| {
        if (try getPasswordChars(&input_buf, seed, i)) |chars| {
            if (pw1_cnt < pw1.len) {
                pw1[pw1_cnt] = chars[0];
                pw1_cnt += 1;
                try stdout.print("First Door: {s} ({}/8)\n", .{ pw1, pw1_cnt });
                try stdout.flush();
            }

            const place = std.fmt.charToDigit(chars[0], 16) catch unreachable;
            if (place < pw2.len and pw2[place] == '*') {
                pw2[place] = chars[1];
                pw2_cnt += 1;
                try stdout.print("Second Door: {s} ({}/8)\n", .{ pw2, pw2_cnt });
                try stdout.flush();
                if (pw2_cnt == pw2.len) {
                    try stdout.print("{} hashes checked\n", .{i});
                    try stdout.flush();
                    break;
                }
            }
        }
    } else {
        return .{ null, null };
    }
    try stdout.writeByte('\n');
    return .{ pw1, pw2 };
}

fn getPasswordChars(buf: []u8, seed: []const u8, index: usize) solver.Error!?[2]u8 {
    var hex: [Md5.digest_length * 2]u8 = undefined;
    hashIndex(seed, index, buf, &hex) catch @panic("Buffer for hash input is not long enough");
    return if (isHashValid(&hex, 5)) .{ hex[5], hex[6] } else null;
}

test "get pw char" {
    var buf: [32]u8 = undefined;
    try std.testing.expectEqual(.{ '1', '5' }, try getPasswordChars(&buf, "abc", 3231929));
    try std.testing.expectEqual(.{ '8', 'f' }, try getPasswordChars(&buf, "abc", 5017308));
    try std.testing.expectEqual(.{ 'f', '9' }, try getPasswordChars(&buf, "abc", 5278568));
}

fn isHashValid(hex: *const [Md5.digest_length * 2]u8, zero_cnt: u5) bool {
    return std.mem.allEqual(u8, hex[0..zero_cnt], '0');
}

test "validate hash" {
    try std.testing.expect(isHashValid("00000000000000000000000000000000", 5));
    try std.testing.expect(isHashValid("00000af5a84868b810948e01453123db", 5));
    try std.testing.expect(!isHashValid("ffffffffffffffffffffffffffffffff", 5));
    try std.testing.expect(!isHashValid("0000ffffffffffffffffffffffffffff", 5));
    try std.testing.expect(isHashValid("0000ffffffffffffffffffffffffffff", 4));
}
