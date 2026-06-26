const std = @import("std");
const lib = @import("lib");

const solver = lib.solver;
const testing = lib.testing;

const Parser = lib.Parser;

const Rect = struct {
    claim_no: u16,
    x1: u16,
    y1: u16,
    x2: u16,
    y2: u16,
};

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var rect_list: std.ArrayList(Rect) = .empty;
    defer rect_list.deinit(tools.gpa);
    var lines = input.lines();
    while (lines.next()) |line| {
        try rect_list.append(tools.gpa, try parseRect(line));
    }

    var coverage: [1000][1000]u2 = .{.{0} ** 1000} ** 1000;
    for (rect_list.items) |rect| {
        for (rect.y1..rect.y2) |y| {
            for (rect.x1..rect.x2) |x| {
                coverage[y][x] +|= 1;
            }
        }
    }
    return .{ countOverlap(&coverage), findNonOverlapping(&coverage, rect_list.items) };
}

pub const solve = solver.intSolver(u32, solveInt);

test "solve" {
    const input =
        \\#1 @ 1,3: 4x4
        \\#2 @ 3,1: 4x4
        \\#3 @ 5,5: 2x2
    ;
    try testing.expectIntSolution(u32, solveInt, .{ 4, 3 }, input);
}

fn parseRect(str: []const u8) Parser.Error!Rect {
    var parser: Parser = .init(str, .{});
    const claim_no = try parser.findInt(u16);
    const lspace = try parser.findInt(u16);
    const tspace = try parser.findInt(u16);
    const width = try parser.findInt(u16);
    const height = try parser.findInt(u16);

    return .{
        .claim_no = claim_no,
        .x1 = lspace,
        .y1 = tspace,
        .x2 = lspace + width,
        .y2 = tspace + height,
    };
}

fn countOverlap(coverage: *const [1000][1000]u2) u32 {
    var count: u32 = 0;
    for (coverage) |row| {
        for (row) |square| {
            if (square >= 2) count += 1;
        }
    }
    return count;
}

fn findNonOverlapping(coverage: *const [1000][1000]u2, rects: []const Rect) ?u32 {
    check_rect: for (rects) |rect| {
        for (rect.y1..rect.y2) |y| {
            for (rect.x1..rect.x2) |x| {
                if (coverage[y][x] > 1) continue :check_rect;
            }
        }
        return rect.claim_no;
    }
    return null;
}
