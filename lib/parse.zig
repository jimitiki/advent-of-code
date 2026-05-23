const std = @import("std");

pub const WordIterator = struct {
    const Self = @This();

    string: []const u8,
    index: usize = 0,
    omit_punctuation: bool = false,
    reverse: bool = false,

    pub fn init(string: []const u8) Self {
        return .{ .string = string };
    }

    pub fn initRev(string: []const u8) Self {
        return .{ .string = string, .index = string.len - 1, .reverse = true };
    }

    pub fn next(self: *Self) ?[]const u8 {
        return if (self.reverse) self.nextRev() else self.nextFwd();
    }

    fn nextFwd(self: *Self) ?[]const u8 {
        while (self.skip()) : (self.index += 1) {}
        if (self.index >= self.string.len) {
            return null;
        }

        const start = self.index;
        while (self.take()) : (self.index += 1) {}
        return self.string[start..self.index];
    }

    fn nextRev(self: *Self) ?[]const u8 {
        while (self.skip()) : (self.index -= 1) {}
        if (self.index <= 0) {
            return null;
        }

        const end = self.index + 1;
        while (self.take()) : (self.index -= 1) {}
        return self.string[self.index + 1 .. end];
    }

    fn skip(self: *Self) bool {
        if (self.reverse and self.index == 0 or self.index >= self.string.len) {
            return false;
        }
        return switch (self.string[self.index]) {
            ' ' => true,
            ',', '.' => self.omit_punctuation,
            else => false,
        };
    }

    fn take(self: *Self) bool {
        if (self.reverse and self.index == 0 or self.index >= self.string.len) {
            return false;
        }
        return switch (self.string[self.index]) {
            ' ' => false,
            ',', '.' => !self.omit_punctuation,
            else => true,
        };
    }
};

pub fn splitWords(buf: [][]const u8, string: []const u8) error{TooManyWords}!?[][]const u8 {
    var it = WordIterator.init(string);
    var i: usize = 0;
    while (it.next()) |word| : (i += 1) {
        if (i >= buf.len) {
            return error.TooManyWords;
        }
        buf[i] = word;
    }
    if (i > 0) {
        return buf[0..i];
    } else {
        return null;
    }
}
