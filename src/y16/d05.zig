const std = @import("std");
const Md5 = std.crypto.hash.Md5;

const solver = @import("../solver.zig");

pub fn solve(_: std.mem.Allocator, input: *std.Io.Reader, buf1: []u8, buf2: []u8) solver.Error!struct { ?[]const u8, ?[]const u8 } {
    const seed = input.peekDelimiterExclusive('\n') catch return error.InvalidInput;
    var pw1: []u8 = buf1[0..8];
    @memset(pw1, '*');
    var pw1_cnt: u4 = 0;

    var pw2: []u8 = buf2[0..8];
    @memset(pw2, '*');
    var pw2_cnt: u4 = 0;

    var input_buf: [128]u8 = undefined;
    for (0..std.math.maxInt(usize)) |i| {
        if (try getPasswordChars(&input_buf, seed, i)) |chars| {
            if (pw1_cnt < pw1.len) {
                pw1[pw1_cnt] = chars[0];
                std.debug.print("First Door: {s} ({}/8)\n", .{ pw1, pw1_cnt });
                pw1_cnt += 1;
            }

            const place = std.fmt.charToDigit(chars[0], 16) catch unreachable;
            if (place < pw2.len and pw2[place] == '*') {
                pw2[place] = chars[1];
                pw2_cnt += 1;
                std.debug.print("Second Door: {s} ({}/8)\n", .{ pw2, pw2_cnt });
                if (pw2_cnt == pw2.len) {
                    std.debug.print("{} hashes checked\n", .{i});
                    break;
                }
            }
        }
    } else {
        return .{ null, null };
    }
    std.debug.print("\n", .{});
    return .{ pw1, pw2 };
}

fn getPasswordChars(buf: []u8, seed: []const u8, index: usize) solver.Error!?[2]u8 {
    const str = std.fmt.bufPrint(buf, "{s}{}", .{ seed, index }) catch @panic("Buffer for hash input is not long enough");
    var hex: [Md5.digest_length * 2]u8 = undefined;
    hashStr(str, &hex);
    return if (isHashValid(&hex, 5)) .{ hex[5], hex[6] } else null;
}

test "get pw char" {
    var buf: [32]u8 = undefined;
    try std.testing.expectEqual(.{ '1', '5' }, try getPasswordChars(&buf, "abc", 3231929));
    try std.testing.expectEqual(.{ '8', 'f' }, try getPasswordChars(&buf, "abc", 5017308));
    try std.testing.expectEqual(.{ 'f', '9' }, try getPasswordChars(&buf, "abc", 5278568));
}

fn hashStr(str: []const u8, buf: *[Md5.digest_length * 2]u8) void {
    var digest: [Md5.digest_length]u8 = undefined;
    Md5.hash(str, &digest, .{});
    for (digest, 0..) |byte, i| {
        _ = std.fmt.bufPrint(buf[i * 2 .. i * 2 + 2], "{x:0>2}", .{byte}) catch unreachable;
    }
}

test "hash" {
    var hex: [Md5.digest_length * 2]u8 = undefined;
    hashStr("abc3231929", &hex);
    try std.testing.expectEqualSlices(u8, "00000155f8105dff7f56ee10fa9b9abd", &hex);
    hashStr("abc5017308", &hex);
    try std.testing.expectEqualSlices(u8, "000008f82c5b3924a1ecbebf60344e00", &hex);
    hashStr("abc5278568", &hex);
    try std.testing.expectEqualSlices(u8, "00000f9a2c309875e05c5a5d09f1b8c4", &hex);
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
