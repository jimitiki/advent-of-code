const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../parse.zig").Parser;

const Sue = std.StringArrayHashMapUnmanaged(u8);

const sue_str = "Sue 0: children: 3, cats: 7, samoyeds: 2, pomeranians: 3, akitas: 0, vizslas: 0, goldfish: 5, trees: 3, cars: 2, perfumes: 1";

// TODO: Maybe "Sue"s should be represented by a struct after all?

fn solveInt(tools: solver.Tools) solver.Error!struct { ?usize, ?usize } {
    var sue = try parseSue(tools.gpa, sue_str);
    defer sue.deinit(tools.gpa);
    var sue1: ?usize = null;
    var sue2: ?usize = null;
    var i: usize = 1;
    while (try tools.input.takeDelimiter('\n')) |line| : (i += 1) {
        var candidate = try parseSue(tools.gpa, line);
        defer candidate.deinit(tools.gpa);
        if (isMatch(sue, candidate, false)) sue1 = i;
        if (isMatch(sue, candidate, true)) sue2 = i;
        if (sue1) |_| {
            if (sue2) |_| break;
        }
    }
    return .{ sue1, sue2 };
}

pub const solve = solver.intSolver(usize, solveInt);

fn parseSue(allocator: std.mem.Allocator, string: []const u8) Parser.Error!Sue {
    var parser: Parser = .init(string, .{});
    try parser.skipMany(2);
    var sue: Sue = .empty;
    errdefer sue.deinit(allocator);
    while (try parseProperty(&parser)) |property| {
        sue.put(allocator, property[0], property[1]) catch unreachable;
    }
    return sue;
}

fn parseProperty(parser: *Parser) Parser.Error!?struct { []const u8, u8 } {
    const name = parser.take() catch return null;
    return .{ name[0 .. name.len - 1], try parser.takeInt(u8) };
}

fn isMatch(lhs: Sue, rhs: Sue, use_ranges: bool) bool {
    var it = lhs.iterator();
    while (it.next()) |entry| {
        if (rhs.get(entry.key_ptr.*)) |expected| {
            if (use_ranges and (std.mem.eql(u8, "cats", entry.key_ptr.*) or std.mem.eql(u8, "trees", entry.key_ptr.*))) {
                if (entry.value_ptr.* >= expected) {
                    return false;
                }
            } else if (use_ranges and (std.mem.eql(u8, "pomeranians", entry.key_ptr.*) or std.mem.eql(u8, "goldfish", entry.key_ptr.*))) {
                if (entry.value_ptr.* <= expected) {
                    return false;
                }
            } else {
                if (expected != entry.value_ptr.*) {
                    return false;
                }
            }
        }
    }
    return true;
}
