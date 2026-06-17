const std = @import("std");

const solver = @import("../solver.zig");

const Range = struct {
    start: u32,
    end: u32,

    fn init(start: u32, end: u32) error{InvalidRange}!Range {
        if (start >= end) return error.InvalidRange;
        return .{ .start = start, .end = end };
    }
};
const RangeList = std.ArrayList(Range);

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    const gpa = tools.gpa;
    var ranges: RangeList = .empty;
    defer ranges.deinit(gpa);
    while (try tools.input.reader.takeDelimiter('\n')) |line| {
        for (line, 0..) |char, i| {
            if (char == '-') {
                // std.debug.print("{s} -> {s} / {s}\n", .{line, line[0]})
                try ranges.append(gpa, Range.init(
                    std.fmt.parseInt(u32, line[0..i], 10) catch return error.InvalidInput,
                    std.fmt.parseInt(u32, line[i + 1 ..], 10) catch return error.InvalidInput,
                ) catch return error.InvalidInput);
                break;
            }
        }
    }
    std.sort.pdq(Range, ranges.items, {}, lessThan);

    var merged: RangeList = .empty;
    defer merged.deinit(gpa);
    var i: usize = 0;
    while (i < ranges.items.len) : (i += 1) {
        var range = ranges.items[i];
        while (i < ranges.items.len - 1 and ranges.items[i + 1].start <= range.end +| 1) : (i += 1) {
            range.end = @max(range.end, ranges.items[i + 1].end);
        }
        try merged.append(gpa, range);
    }

    const first_range = merged.items[0];
    var allowed: u32 = first_range.start + (std.math.maxInt(u32) - merged.items[merged.items.len - 1].end);
    for (merged.items[0 .. merged.items.len - 1], merged.items[1..]) |a, b| {
        allowed += b.start - a.end - 1;
    }
    return .{
        if (first_range.start > 0) 0 else first_range.end + 1,
        allowed,
    };
}

pub const solve = solver.intSolver(u32, solveInt);

fn lessThan(_: void, lhs: Range, rhs: Range) bool {
    return lhs.start < rhs.start;
}
