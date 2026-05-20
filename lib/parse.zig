const std = @import("std");

pub const WordIterator = struct {
    const Self = @This();

    string: []const u8,
    index: usize = 0,

    pub fn init(string: []const u8) Self {
        return .{ .string = string };
    }

    pub fn next(self: *Self) ?[]const u8 {
        while (self.index < self.string.len and self.string[self.index] == ' ') : (self.index += 1) {}
        if (self.index >= self.string.len) {
            return null;
        }

        const start = self.index;
        while (self.index < self.string.len and self.string[self.index] != ' ') : (self.index += 1) {}
        return self.string[start..self.index];
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
