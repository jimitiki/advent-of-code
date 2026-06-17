const std = @import("std");

const solver = @import("../solver.zig");
const Counter = @import("../counter.zig").Counter(u8);

const Room = struct {
    name: []const u8,
    sector: u32,
    chksum: []const u8,

    pub fn validate(room: Room, allocator: std.mem.Allocator) error{OutOfMemory}!bool {
        var counter: Counter = .empty;
        defer counter.deinit(allocator);
        for (room.name) |char| {
            if (char >= 'a' and char <= 'z') {
                _ = try counter.add(allocator, char);
            }
        }
        return std.mem.eql(u8, counter.topKeys(5), room.chksum);
    }

    pub fn parse(str: []const u8) !Room {
        return .{
            .name = str[0 .. str.len - 11],
            .sector = std.fmt.parseUnsigned(u32, str[str.len - 10 .. str.len - 7], 10) catch return error.InvalidInput,
            .chksum = str[str.len - 6 .. str.len - 1],
        };
    }

    pub fn decrypt(self: Room, buf: []u8) []const u8 {
        const offset: u8 = @intCast(self.sector % 26);
        for (self.name, 0..) |char, i| {
            if (char == '-') {
                buf[i] = ' ';
            } else {
                buf[i] = (char - 'a' + offset) % 26 + 'a';
            }
        }
        return buf[0..self.name.len];
    }
};

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var sum_valid: u32 = 0;
    var obj_storage_sector: ?u32 = null;
    var buf: [64]u8 = undefined;
    while (try input.reader.takeDelimiter('\n')) |line| {
        const room = try Room.parse(line);
        if (!try room.validate(tools.gpa)) {
            continue;
        }
        sum_valid += room.sector;
        if (obj_storage_sector) |_| {} else {
            if (std.mem.eql(u8, room.decrypt(&buf), "northpole object storage")) {
                obj_storage_sector = room.sector;
            }
        }
    }

    return .{ sum_valid, obj_storage_sector };
}

pub const solve = solver.intSolver(u32, solveInt);

test "parse" {
    {
        const expected: Room = .{
            .name = "aaaaa-bbb-z-y-x",
            .sector = 123,
            .chksum = "abxyz",
        };
        const actual = try Room.parse("aaaaa-bbb-z-y-x-123[abxyz]");
        try std.testing.expectEqualSlices(u8, expected.name, actual.name);
        try std.testing.expectEqual(expected.sector, actual.sector);
        try std.testing.expectEqualSlices(u8, expected.chksum, actual.chksum);
    }
    {
        const expected: Room = .{
            .name = "a-b-c-d-e-f-g-h",
            .sector = 987,
            .chksum = "abcde",
        };
        const actual = try Room.parse("a-b-c-d-e-f-g-h-987[abcde]");
        try std.testing.expectEqualSlices(u8, expected.name, actual.name);
        try std.testing.expectEqual(expected.sector, actual.sector);
        try std.testing.expectEqualSlices(u8, expected.chksum, actual.chksum);
    }
    {
        const expected: Room = .{
            .name = "not-a-real-room",
            .sector = 404,
            .chksum = "oarel",
        };
        const actual = try Room.parse("not-a-real-room-404[oarel]");
        try std.testing.expectEqualSlices(u8, expected.name, actual.name);
        try std.testing.expectEqual(expected.sector, actual.sector);
        try std.testing.expectEqualSlices(u8, expected.chksum, actual.chksum);
    }
    {
        const expected: Room = .{
            .name = "totally-real-room",
            .sector = 200,
            .chksum = "decoy",
        };
        const actual = try Room.parse("totally-real-room-200[decoy]");
        try std.testing.expectEqualSlices(u8, expected.name, actual.name);
        try std.testing.expectEqual(expected.sector, actual.sector);
        try std.testing.expectEqualSlices(u8, expected.chksum, actual.chksum);
    }
}

test "validation" {
    const room1: Room = .{ .name = "aaaaa-bbb-z-y-x", .sector = 123, .chksum = "abxyz" };
    try std.testing.expect(try room1.validate(std.testing.allocator));
    const room2: Room = .{ .name = "a-b-c-d-e-f-g-h", .sector = 987, .chksum = "abcde" };
    try std.testing.expect(try room2.validate(std.testing.allocator));
    const room3: Room = .{ .name = "not-a-real-room", .sector = 404, .chksum = "oarel" };
    try std.testing.expect(try room3.validate(std.testing.allocator));
    const room4: Room = .{ .name = "totally-real-room", .sector = 200, .chksum = "decoy" };
    try std.testing.expect(!try room4.validate(std.testing.allocator));
}

test "decrypt" {
    var buf: [64]u8 = undefined;
    const room: Room = .{ .name = "qzmt-zixmtkozy-ivhz", .sector = 343, .chksum = "" };
    try std.testing.expectEqualSlices(u8, "very encrypted name", room.decrypt(&buf));
}

test "solve" {
    const t = @import("../test.zig");
    const input = "aaaaa-bbb-z-y-x-123[abxyz]\na-b-c-d-e-f-g-h-987[abcde]\nnot-a-real-room-404[oarel]\ntotally-real-room-200[decoy]";
    try t.expectIntSolution(u32, solveInt, .{ 1514, null }, input);
}
