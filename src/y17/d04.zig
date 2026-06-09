const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

const WordSet = std.StringHashMapUnmanaged(void);

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    var wordset: WordSet = .empty;
    defer wordset.deinit(tools.gpa);

    var count: u16 = 0;
    while (try tools.input.takeDelimiter('\n')) |line| {
        if (try isValid(tools.gpa, &wordset, line)) {
            count += 1;
        }
    }
    return .{ count, null };
}

pub const solve = solver.intSolver(u16, solveInt);

fn isValid(gpa: std.mem.Allocator, wordset: *WordSet, passphrase: []const u8) error{OutOfMemory}!bool {
    wordset.clearRetainingCapacity();
    var parser: Parser = .init(passphrase, .{});
    while (true) {
        const word = parser.take() catch break;
        const result = try wordset.getOrPut(gpa, word);
        if (result.found_existing) {
            return false;
        }
    }
    return true;
}

test "validation" {
    const gpa = std.testing.allocator;
    var wordset: WordSet = .empty;
    defer wordset.deinit(gpa);

    try std.testing.expect(try isValid(gpa, &wordset, "aa bb cc dd ee"));
    try std.testing.expect(!try isValid(gpa, &wordset, "aa bb cc dd aa"));
    try std.testing.expect(try isValid(gpa, &wordset, "aa bb cc dd aaa"));
}
