const std = @import("std");
const lib = @import("lib");

const solver = lib.solver;

// TODO: Is there a way to avoid generating data to fill the whole disk?

pub fn solve(input: solver.Input, tools: solver.Tools, p1buf: *[32]u8, p2buf: *[32]u8) solver.Error!solver.Result {
    var parser = input.parser(.{});
    const str = try parser.take();
    var max_size = str.len;
    while (max_size < 35651584) : (max_size = max_size * 2 + 1) {}
    const buf = try tools.gpa.alloc(u8, max_size);
    defer tools.gpa.free(buf);

    const p1chksum = computeChksum(buf, 272, str);
    @memcpy(p1buf[0..p1chksum.len], p1chksum);
    const p2chksum = computeChksum(buf, 35651584, str);
    std.debug.print("{s}\n", .{p2chksum});
    @memcpy(p2buf[0..p2chksum.len], p2chksum);
    return .{ p1buf[0..p1chksum.len], p2buf[0..p2chksum.len] };
}

fn computeChksum(buf: []u8, disk_size: usize, input: []const u8) []const u8 {
    var bits = generateData(buf, disk_size, input);
    while (bits.len % 2 == 0) {
        const chksum = bits[0..@divExact(bits.len, 2)];
        for (0..chksum.len) |i| {
            chksum[i] = if (bits[i * 2] == bits[i * 2 + 1]) '1' else '0';
        }
        bits = chksum;
    }
    return bits;
}

test "chksum" {
    var buf: [23]u8 = undefined;
    try std.testing.expectEqualSlices(u8, "01100", computeChksum(&buf, 20, "10000"));
}

fn generateData(buf: []u8, disk_size: usize, original: []const u8) []u8 {
    @memcpy(buf[0..original.len], original);
    var size = original.len;
    var new_size = size * 2 + 1;
    while (size < disk_size) : ({
        size = new_size;
        new_size = new_size * 2 + 1;
    }) {
        buf[size] = '0';
        for (buf[0..size], 0..) |bit, i| {
            buf[new_size - 1 - i] = if (bit == '1') '0' else '1';
        }
    }
    return buf[0..disk_size];
}

test "generate" {
    var buf: [25]u8 = undefined;
    try std.testing.expectEqualSlices(u8, "100", generateData(&buf, 3, "1"));
    try std.testing.expectEqualSlices(u8, "001", generateData(&buf, 3, "0"));
    try std.testing.expectEqualSlices(u8, "11111000000", generateData(&buf, 11, "11111"));
    try std.testing.expectEqualSlices(u8, "1111000010100101011110000", generateData(&buf, 25, "111100001010"));
    try std.testing.expectEqualSlices(u8, "10000011110010000111", generateData(&buf, 20, "10000"));
}
