const std = @import("std");
const Md5 = std.crypto.hash.Md5;

const solver = @import("../solver.zig");

pub fn solve(tools: solver.Tools) solver.Error!solver.Result {
    const passcode = try tools.input.takeDelimiter('\n') orelse return error.InvalidInput;
    var hashbuf: [256]u8 = undefined;
    var pathbuf: [256]u8 = undefined;
    @memcpy(hashbuf[0..passcode.len], passcode);
    const best_path = findBestPath(&pathbuf, &hashbuf, passcode.len, std.math.maxInt(usize), "", 0, 0);
    if (best_path) |p| {
        @memcpy(tools.p1buf[0..p.len], p);
    }
    return .{ best_path, null };
}

fn findBestPath(pathbuf: []u8, hashbuf: []u8, plen: usize, min: usize, path: []const u8, x: usize, y: usize) ?[]const u8 {
    if (min < path.len) return null;
    if (x == 3 and y == 3) {
        @memcpy(pathbuf[0..path.len], path);
        return pathbuf[0..path.len];
    }
    var digest: [Md5.digest_length]u8 = undefined;
    Md5.hash(hashbuf[0 .. plen + path.len], &digest, .{});
    var best_path: ?[]const u8 = null;
    for (0..4) |i| {
        const hex: u4 = if (i & 1 == 0) @intCast(digest[i / 2] >> 4) else @truncate(digest[i / 2]);
        if (hex < 0xb) {
            continue;
        }
        const step: u8, const xnext, const ynext = switch (i) {
            0 => if (y > 0) .{ 'U', x, y - 1 } else continue,
            1 => if (y < 3) .{ 'D', x, y + 1 } else continue,
            2 => if (x > 0) .{ 'L', x - 1, y } else continue,
            3 => if (x < 3) .{ 'R', x + 1, y } else continue,
            else => unreachable,
        };
        hashbuf[plen + path.len] = step;
        const best = if (best_path) |p| p.len else min;
        if (findBestPath(pathbuf, hashbuf, plen, best, hashbuf[plen .. plen + path.len + 1], xnext, ynext)) |final_path| {
            best_path = final_path;
        }
    }
    return best_path;
}

test "best path" {
    var hbuf: [256]u8 = undefined;
    var pbuf: [256]u8 = undefined;
    {
        @memcpy(hbuf[0..8], "ihgpwlah");
        try std.testing.expectEqualSlices(u8, "DDRRRD", findBestPath(&pbuf, &hbuf, 8, std.math.maxInt(usize), "", 0, 0).?);
    }
    {
        @memcpy(hbuf[0..8], "kglvqrro");
        try std.testing.expectEqualSlices(u8, "DDUDRLRRUDRD", findBestPath(&pbuf, &hbuf, 8, std.math.maxInt(usize), "", 0, 0).?);
    }
    {
        @memcpy(hbuf[0..8], "ulqzkmiv");
        try std.testing.expectEqualSlices(u8, "DRURDRUDDLLDLUURRDULRLDUUDDDRR", findBestPath(&pbuf, &hbuf, 8, std.math.maxInt(usize), "", 0, 0).?);
    }
}
