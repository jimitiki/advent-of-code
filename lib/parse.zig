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
