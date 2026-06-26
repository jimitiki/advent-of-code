const std = @import("std");
const Md5 = std.crypto.hash.Md5;

pub fn hashStr(str: []const u8, buf: *[Md5.digest_length * 2]u8) void {
    var digest: [Md5.digest_length]u8 = undefined;
    Md5.hash(str, &digest, .{});
    for (digest, 0..) |byte, i| {
        _ = std.fmt.bufPrint(buf[i * 2 .. i * 2 + 2], "{x:0>2}", .{byte}) catch unreachable;
    }
}

pub fn hashIndex(salt: []const u8, index: u64, buf: []u8, out: *[32]u8) error{NoSpaceLeft}!void {
    const input = try std.fmt.bufPrint(buf, "{s}{}", .{ salt, index });
    hashStr(input, out);
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
