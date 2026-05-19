const std = @import("std");
const Md5 = std.crypto.hash.Md5;

const Boilerplate = @import("lib").Boilerplate;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;
    var answer: u64 = 0;
    const zero_cnt: usize = switch (bp.part) {
        .p1 => 5,
        .p2 => 6,
    };
    if (try input.takeDelimiter('\n')) |line| {
        var buf: [128]u8 = undefined;
        var i: u64 = 0;
        while (!try checkHash(&buf, line, i, zero_cnt)) : (i += 1) {} else {
            answer = i;
        }
    } else return error.InvalidInput;

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn checkHash(buf: []u8, prefix: []const u8, suffix: u64, zero_cnt: usize) !bool {
    const input = try std.fmt.bufPrint(buf, "{s}{}", .{ prefix, suffix });
    var digest: [Md5.digest_length]u8 = undefined;
    Md5.hash(input, &digest, .{});
    var hex: [Md5.digest_length * 2]u8 = undefined;
    for (digest, 0..) |byte, i| {
        _ = try std.fmt.bufPrint(hex[i * 2 .. i * 2 + 2], "{x:0>2}", .{byte});
    }
    return std.mem.allEqual(u8, hex[0..zero_cnt], '0');
}
