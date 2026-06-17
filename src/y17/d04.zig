const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

const WordSet = std.StringHashMapUnmanaged(void);

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    var wordset: WordSet = .empty;
    defer wordset.deinit(tools.gpa);

    var no_repeats: u16 = 0;
    var no_anagrams: u16 = 0;
    while (try tools.input.reader.takeDelimiter('\n')) |line| {
        if (!try hasRepeat(tools.gpa, &wordset, line)) {
            no_repeats += 1;
        }
        if (!try hasAnagram(tools.gpa, &wordset, line)) {
            no_anagrams += 1;
        }
    }
    return .{ no_repeats, no_anagrams };
}

pub const solve = solver.intSolver(u16, solveInt);

fn hasRepeat(gpa: std.mem.Allocator, wordset: *WordSet, passphrase: []const u8) error{OutOfMemory}!bool {
    wordset.clearRetainingCapacity();
    var parser: Parser = .init(passphrase, .{});
    while (true) {
        const word = parser.take() catch break;
        const result = try wordset.getOrPut(gpa, word);
        if (result.found_existing) {
            return true;
        }
    }
    return false;
}

test "repeat words" {
    const gpa = std.testing.allocator;
    var wordset: WordSet = .empty;
    defer wordset.deinit(gpa);

    try std.testing.expect(!try hasRepeat(gpa, &wordset, "aa bb cc dd ee"));
    try std.testing.expect(try hasRepeat(gpa, &wordset, "aa bb cc dd aa"));
    try std.testing.expect(!try hasRepeat(gpa, &wordset, "aa bb cc dd aaa"));
}

fn hasAnagram(gpa: std.mem.Allocator, wordset: *WordSet, passphrase: []const u8) error{OutOfMemory}!bool {
    wordset.clearRetainingCapacity();
    defer {
        var it = wordset.keyIterator();
        while (it.next()) |word| gpa.free(word.*);
    }
    var parser: Parser = .init(passphrase, .{});
    while (true) {
        const word = parser.take() catch break;
        const sorted = try gpa.alloc(u8, word.len);
        @memcpy(sorted, word);
        std.sort.pdq(u8, sorted, {}, lessThan);
        const result = try wordset.getOrPut(gpa, sorted);
        if (result.found_existing) {
            gpa.free(sorted);
            return true;
        }
    }
    return false;
}

fn lessThan(_: void, a: u8, b: u8) bool {
    return a < b;
}

test "anagrams" {
    const gpa = std.testing.allocator;
    var wordset: WordSet = .empty;
    defer wordset.deinit(gpa);
    try std.testing.expect(!try hasAnagram(gpa, &wordset, "abcde fghij"));
    try std.testing.expect(try hasAnagram(gpa, &wordset, "abcde xyz ecdab"));
    try std.testing.expect(!try hasAnagram(gpa, &wordset, "a ab abc abd abf abj"));
    try std.testing.expect(!try hasAnagram(gpa, &wordset, "iiii oiii ooii oooi oooo"));
    try std.testing.expect(try hasAnagram(gpa, &wordset, "oiii ioii iioi iiio"));
}
