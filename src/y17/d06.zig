const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    const gpa = tools.gpa;
    var bank_list: std.ArrayList(u8) = .empty;
    defer bank_list.deinit(gpa);

    try parseBanks(gpa, &bank_list, tools.input);
    return try cycle(gpa, bank_list.items);
}

pub const solve = solver.intSolver(u32, solveInt);

fn parseBanks(gpa: std.mem.Allocator, bank_list: *std.ArrayList(u8), reader: *std.Io.Reader) solver.Error!void {
    const input = try reader.takeDelimiter('\n') orelse return error.InvalidInput;
    var parser: Parser = .init(input, .{});
    while (true) {
        if (parser.takeInt(u8)) |blocks| {
            try bank_list.append(gpa, blocks);
        } else |err| {
            switch (err) {
                error.EndOfBuffer => break,
                else => |e| return e,
            }
        }
    }
}

fn cycle(gpa: std.mem.Allocator, initial: []u8) error{OutOfMemory}!struct { u16, u16 } {
    var seen: std.StringHashMapUnmanaged(u16) = .empty;
    defer {
        var it = seen.keyIterator();
        while (it.next()) |sequence| gpa.free(sequence.*);
        seen.deinit(gpa);
    }

    var i: u16 = 0;
    const banks = initial;
    while (!seen.contains(banks)) : ({
        reallocate(banks);
        i += 1;
    }) {
        const allocated = try gpa.alloc(u8, banks.len);
        @memcpy(allocated, banks);
        try seen.put(gpa, allocated, i);
    }
    return .{ i, i - seen.get(banks).? };
}

test "cycle" {
    var banks = [_]u8{ 0, 2, 7, 0 };
    try std.testing.expectEqual(.{ 5, 4 }, cycle(std.testing.allocator, &banks));
}

fn reallocate(banks: []u8) void {
    var i = std.mem.findMax(u8, banks);
    var j = banks[i];
    banks[i] = 0;
    i = (i + 1) % banks.len;
    while (j > 0) : ({
        i = (i + 1) % banks.len;
        j -= 1;
    }) {
        banks[i] += 1;
    }
}

test "reallocate" {
    var banks = [_]u8{ 0, 2, 7, 0 };
    reallocate(&banks);
    try std.testing.expectEqual(.{ 2, 4, 1, 2 }, banks);
    reallocate(&banks);
    try std.testing.expectEqual(.{ 3, 1, 2, 3 }, banks);
    reallocate(&banks);
    try std.testing.expectEqual(.{ 0, 2, 3, 4 }, banks);
    reallocate(&banks);
    try std.testing.expectEqual(.{ 1, 3, 4, 1 }, banks);
    reallocate(&banks);
    try std.testing.expectEqual(.{ 2, 4, 1, 2 }, banks);
}
