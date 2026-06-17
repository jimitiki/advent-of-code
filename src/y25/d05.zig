const std = @import("std");

const solver = @import("../solver.zig");

const Range = struct {
    start: u64,
    end: u64,

    pub fn lessThan(_: void, lhs: Range, rhs: Range) bool {
        return lhs.start < rhs.start;
    }
};

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u64, ?u64 } {
    const gpa = tools.gpa;

    //Read ID ranges from file
    var ranges_raw: std.ArrayList(Range) = .empty;
    defer ranges_raw.deinit(gpa);
    while (try input.reader.takeDelimiter('\n')) |line| {
        if (line.len == 0) break;
        var split_point: usize = 0;
        while (line[split_point] != '-') : (split_point += 1) {}
        const start = std.fmt.parseInt(u64, line[0..split_point], 10) catch return error.InvalidInput;
        const end = std.fmt.parseInt(u64, line[split_point + 1 ..], 10) catch return error.InvalidInput;
        try ranges_raw.append(gpa, .{ .start = start, .end = end });
    }

    // Merge overlapping ranges
    std.sort.pdq(Range, ranges_raw.items, {}, Range.lessThan);
    var ranges: std.ArrayList(Range) = .empty;
    defer ranges.deinit(gpa);
    var range_merged: Range = .{ .start = ranges_raw.items[0].start, .end = ranges_raw.items[0].end };
    for (ranges_raw.items) |range| {
        if (range.start > range_merged.end) {
            try ranges.append(gpa, range_merged);
            range_merged = range;
        } else {
            range_merged.end = @max(range.end, range_merged.end);
        }
    } else {
        try ranges.append(gpa, range_merged);
    }

    // Find which input IDs are valid
    var answer1: u64 = 0;
    while (try input.reader.takeDelimiter('\n')) |line| {
        const id = std.fmt.parseInt(u64, line, 10) catch return error.InvalidInput;
        for (ranges.items) |range| {
            if (id >= range.start and id <= range.end) {
                answer1 += 1;
            }
        }
    }

    // Count all valid IDs
    var answer2: u64 = 0;
    for (ranges.items) |range| {
        answer2 += range.end - range.start + 1;
    }
    return .{ answer1, answer2 };
}

pub const solve = solver.intSolver(u64, solveInt);
