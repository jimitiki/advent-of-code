const std = @import("std");

const solver = @import("../solver.zig");
const Counter = @import("../counter.zig").Counter(u8);

pub fn solve(tools: solver.Tools) solver.Error!struct { ?[]const u8, ?[]const u8 } {
    const gpa = tools.gpa;
    const first_code = try tools.input.reader.takeDelimiter('\n') orelse return error.InvalidInput;
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
    while (try tools.input.reader.takeDelimiter('\n')) |code| {
        if (code.len != code_len) {
            return error.InvalidInput;
        }
        for (code, counters) |char, *counter| {
            _ = try counter.add(gpa, char);
        }
    }
    for (counters, tools.p1buf[0..code_len], tools.p2buf[0..code_len]) |counter, *char1, *char2| {
        char1.* = counter.max()[0];
        char2.* = counter.min()[0];
    }
    return .{ tools.p1buf[0..code_len], tools.p2buf[0..code_len] };
}

test "solve" {
    const t = @import("../test.zig");
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
    try t.expectSolution(solve, .{ "easter", "advent" }, text);
}
