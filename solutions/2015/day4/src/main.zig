const std = @import("std");

const Boilerplate = @import("boilerplate").Boilerplate;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;
    var answer: u64 = 0;
    if (try input.takeDelimiter('\n')) |line| {
        var buf: [128]u8 = undefined;
        var i: u64 = 0;
        while (!try checkHash(&buf, line, i)) : (i += 1) {} else {
            answer = i;
        }
    } else return error.InvalidInput;

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn checkHash(buf: []u8, prefix: []const u8, suffix: u64) !bool {
    const input = try std.fmt.bufPrint(buf, "{s}{}", .{ prefix, suffix });
    var digest: [std.crypto.hash.Md5.digest_length]u8 = undefined;
    std.crypto.hash.Md5.hash(input, &digest, .{});
    return digest[0] == 0 and digest[1] == 0 and digest[2] <= 16;
}
