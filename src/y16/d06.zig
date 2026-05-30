const std = @import("std");

const solver = @import("../solver.zig");
const Counter = @import("../counter.zig").Counter(u8);

pub fn solve(gpa: std.mem.Allocator, input: *std.Io.Reader, buf1: []u8, buf2: []u8) solver.Error!struct { ?[]const u8, ?[]const u8 } {
    const first_code = try input.takeDelimiter('\n') orelse return error.InvalidInput;
    const code_len = first_code.len;
    const counters = try gpa.alloc(Counter, code_len);
    defer {
        for (counters) |*counter| {
            counter.deinit(gpa);
        }
        gpa.free(counters);
    }
    for (first_code, counters) |char, *counter| {
        counter.* = .empty;
        try counter.map.ensureTotalCapacity(gpa, 26);
        _ = try counter.add(gpa, char);
    }
    while (try input.takeDelimiter('\n')) |code| {
        if (code.len != code_len) {
            return error.InvalidInput;
        }
        for (code, counters) |char, *counter| {
            _ = try counter.add(gpa, char);
        }
    }
    for (counters, buf1[0..code_len], buf2[0..code_len]) |counter, *char1, *char2| {
        char1.* = counter.max()[0];
        char2.* = counter.min()[0];
    }
    return .{ buf1[0..code_len], buf2[0..code_len] };
}

test "solve" {
    const text =
        \\eedadn
        \\drvtee
        \\eandsr
        \\raavrd
        \\atevrs
        \\tsrnev
        \\sdttsa
        \\rasrtv
        \\nssdts
        \\ntnada
        \\svetve
        \\tesnvt
        \\vntsnd
        \\vrdear
        \\dvrsen
        \\enarar
    ;
    var reader = std.Io.Reader.fixed(text);
    var buf1: [6]u8 = undefined;
    var buf2: [6]u8 = undefined;
    const actual = try solve(std.testing.allocator, &reader, &buf1, &buf2);
    try std.testing.expectEqualSlices(u8, "easter", actual[0].?);
    try std.testing.expectEqualSlices(u8, "advent", actual[1].?);
}
