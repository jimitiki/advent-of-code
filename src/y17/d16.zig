const std = @import("std");

const solver = @import("../solver.zig");

const Ring = struct {
    buf: []u8,
    head: u8 = 0,

    const Error = error{InvalidInstruction};

    pub fn init(buf: []u8) Ring {
        return .{ .buf = buf };
    }

    pub fn spin(self: *Ring, n: u8) Error!void {
        if (n > self.buf.len) return error.InvalidInstruction;
        self.head = @intCast(self.bufIndex(@as(u8, @intCast(self.buf.len)) - n));
    }

    pub fn exchange(self: *Ring, a: u8, b: u8) Error!void {
        if (a > self.buf.len or b > self.buf.len) return error.InvalidInstruction;
        self.swap(self.bufIndex(a), self.bufIndex(b));
    }

    pub fn partner(self: *Ring, a: u8, b: u8) Error!void {
        self.swap(
            self.find(a) orelse return error.InvalidInstruction,
            self.find(b) orelse return error.InvalidInstruction,
        );
    }

    pub fn bufCopy(self: Ring, buf: []u8) []u8 {
        const start = self.buf.len - self.head;
        @memcpy(buf[0..start], self.buf[self.head..]);
        @memcpy(buf[start..self.buf.len], self.buf[0..self.head]);
        return buf[0..self.buf.len];
    }

    fn swap(self: *Ring, ia: usize, ib: usize) void {
        const temp = self.buf[ia];
        self.buf[ia] = self.buf[ib];
        self.buf[ib] = temp;
    }

    fn find(self: Ring, char: u8) ?usize {
        for (self.buf, 0..) |c, i| {
            if (c == char) return i;
        }
        return null;
    }

    fn bufIndex(self: Ring, i: u8) usize {
        const absolute = self.head + i;
        if (absolute >= self.buf.len) {
            return absolute - self.buf.len;
        } else {
            return absolute;
        }
    }
};

test "ring" {
    var buf: [5]u8 = undefined;
    @memcpy(&buf, "abcde");
    var line: Ring = .init(&buf);
    try line.spin(1);
    try std.testing.expectEqualSlices(u8, "abcde", line.buf);
    try std.testing.expectEqual(4, line.head);
    try line.exchange(3, 4);
    try std.testing.expectEqualSlices(u8, "abdce", line.buf);
    try std.testing.expectEqual(4, line.head);
    try line.partner('e', 'b');
    try std.testing.expectEqualSlices(u8, "aedcb", line.buf);
    try std.testing.expectEqual(4, line.head);

    var out: [5]u8 = undefined;
    const str = line.bufCopy(&out);
    try std.testing.expectEqualSlices(u8, "baedc", str);
}

pub fn solve(tools: solver.Tools) solver.Error!solver.Result {
    var buf: [16]u8 = undefined;
    @memcpy(&buf, "abcdefghijklmnop");
    var line: Ring = .init(&buf);
    while (try tools.input.takeDelimiter(',')) |step| {
        switch (step[0]) {
            's' => line.spin(try parseInt(step[1..])) catch return error.InvalidInput,
            'x' => {
                for (step[1..], 1..) |c, i| {
                    if (c != '/') continue;
                    line.exchange(
                        try parseInt(step[1..i]),
                        try parseInt(step[i + 1 ..]),
                    ) catch return error.InvalidInput;
                }
            },
            'p' => line.partner(step[1], step[3]) catch return error.InvalidInput,
            else => return error.InvalidInput,
        }
    }
    std.debug.print("{s} [{}]\n", .{ line.buf, line.head });
    return .{ line.bufCopy(tools.p1buf), null };
}

fn parseInt(str: []const u8) error{InvalidInput}!u8 {
    const buf = if (str[str.len - 1] == '\n') str[0 .. str.len - 1] else str;
    return std.fmt.parseInt(u8, buf, 10) catch error.InvalidInput;
}
