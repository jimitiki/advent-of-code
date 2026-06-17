const std = @import("std");

const solver = @import("../solver.zig");

const Ring = struct {
    buf: []u8,
    head: u8 = 0,

    const Error = error{InvalidInput};

    pub fn init(buf: []u8) Ring {
        return .{ .buf = buf };
    }

    pub fn spin(self: *Ring, n: u8) Error!void {
        if (n > self.buf.len) return error.InvalidInput;
        self.head = @intCast(self.bufIndex(@as(u8, @intCast(self.buf.len)) - n));
    }

    pub fn exchange(self: *Ring, a: u8, b: u8) Error!void {
        if (a > self.buf.len or b > self.buf.len) return error.InvalidInput;
        self.swap(self.bufIndex(a), self.bufIndex(b));
    }

    pub fn partner(self: *Ring, a: u8, b: u8) Error!void {
        self.swap(
            self.find(a) orelse return error.InvalidInput,
            self.find(b) orelse return error.InvalidInput,
        );
    }

    pub fn bufCopy(self: Ring, buf: []u8) void {
        const start = self.buf.len - self.head;
        @memcpy(buf[0..start], self.buf[self.head..]);
        @memcpy(buf[start..], self.buf[0..self.head]);
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

    var str: [5]u8 = undefined;
    line.bufCopy(&str);
    try std.testing.expectEqualSlices(u8, "baedc", &str);
}

const Step = union(enum) {
    s: u8,
    x: struct { u8, u8 },
    p: struct { u8, u8 },
};

pub fn solve(tools: solver.Tools) solver.Error!solver.Result {
    var steps: std.ArrayList(Step) = .empty;
    defer steps.deinit(tools.gpa);
    while (try tools.input.reader.takeDelimiter(',')) |step| {
        switch (step[0]) {
            's' => try steps.append(tools.gpa, .{ .s = try parseInt(step[1..]) }),
            'x' => {
                for (step[1..], 1..) |c, i| {
                    if (c != '/') continue;
                    try steps.append(tools.gpa, .{ .x = .{
                        try parseInt(step[1..i]),
                        try parseInt(step[i + 1 ..]),
                    } });
                    break;
                }
            },
            'p' => try steps.append(tools.gpa, .{ .p = .{ step[1], step[3] } }),
            else => return error.InvalidInput,
        }
    }

    const start = "abcdefghijklmnop";
    var buf: [start.len]u8 = undefined;
    @memcpy(&buf, start);
    var line: Ring = .init(&buf);

    const first = tools.p1buf[0..start.len];
    const cur = tools.p2buf[0..start.len];
    var i: usize = 0;
    while (!std.mem.eql(u8, cur, start)) : (i += 1) {
        try executeSteps(steps.items, &line);
        line.bufCopy(cur);
        if (i == 0) {
            @memcpy(first, cur);
        }
    }
    const mod = 1_000_000_000 % i;
    for (0..mod) |_| {
        try executeSteps(steps.items, &line);
    }
    line.bufCopy(cur);
    return .{ first, cur };
}

fn parseInt(str: []const u8) error{InvalidInput}!u8 {
    const buf = if (str[str.len - 1] == '\n') str[0 .. str.len - 1] else str;
    return std.fmt.parseInt(u8, buf, 10) catch error.InvalidInput;
}

fn executeSteps(steps: []Step, line: *Ring) error{InvalidInput}!void {
    for (steps) |step| {
        switch (step) {
            .s => |n| try line.spin(n),
            .p => |chars| try line.partner(chars[0], chars[1]),
            .x => |indices| try line.exchange(indices[0], indices[1]),
        }
    }
}
