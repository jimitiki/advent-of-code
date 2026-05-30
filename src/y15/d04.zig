const std = @import("std");
const Md5 = std.crypto.hash.Md5;
const solver = @import("../solver.zig");

// TODO: Re-implement MD5?
// TODO: Apparently the input seed "cxsaadws" solves in under 500 hashes. Use it for unit tests

fn solveInt(_: std.mem.Allocator, input: *std.Io.Reader) solver.Error!struct { ?u32, ?u32 } {
    const string = try input.takeDelimiter('\n') orelse return error.InvalidInput;

    var buf: [128]u8 = undefined;
    var answer1: u32 = 0;
    var answer2: u32 = 0;
    while (!try checkHash(&buf, string, answer1, 5)) : (answer1 += 1) {}
    while (!try checkHash(&buf, string, answer2, 6)) : (answer2 += 1) {}

    return .{ answer1, answer2 };
}

pub const solve = solver.intSolver(u32, solveInt);

fn checkHash(buf: []u8, prefix: []const u8, suffix: u32, zero_cnt: usize) !bool {
    const input = std.fmt.bufPrint(buf, "{s}{}", .{ prefix, suffix }) catch unreachable;
    var digest: [Md5.digest_length]u8 = undefined;
    Md5.hash(input, &digest, .{});
    var hex: [Md5.digest_length * 2]u8 = undefined;
    for (digest, 0..) |byte, i| {
        _ = std.fmt.bufPrint(hex[i * 2 .. i * 2 + 2], "{x:0>2}", .{byte}) catch unreachable;
    }
    return std.mem.allEqual(u8, hex[0..zero_cnt], '0');
}
