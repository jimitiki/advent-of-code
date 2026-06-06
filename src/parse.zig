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

pub const Parser = struct {
    pub const Options = struct {
        skip_punctuation: bool = true,
    };

    buf: []const u8,
    index: usize = 0,
    options: Options = .{},

    const Self = @This();

    pub const TakeError = error{EndOfBuffer};
    pub const Error = TakeError || error{InvalidToken};

    pub fn init(buf: []const u8, options: Options) Self {
        return .{ .buf = buf, .options = options };
    }

    pub fn peek(self: *Self) ?[]const u8 {
        while (self.index < self.buf.len and self.isDelimiter(self.buf[self.index])) : (self.index += 1) {}
        if (self.index >= self.buf.len) {
            return null;
        }

        var end = self.index;
        while (end < self.buf.len and !self.isDelimiter(self.buf[end])) : (end += 1) {}
        return self.buf[self.index..end];
    }

    pub fn take(self: *Self) Self.TakeError![]const u8 {
        const token = self.peek() orelse return error.EndOfBuffer;
        self.index += token.len;
        return token;
    }

    pub fn skip(self: *Self) Self.TakeError!void {
        _ = try self.take();
    }

    pub fn takeByte(self: *Self) Self.Error!u8 {
        const token = self.peek() orelse return error.EndOfBuffer;
        if (token.len != 1) return error.InvalidToken;
        self.index += token.len;
        return token[0];
    }

    pub fn takeToken(self: *Self, token: []const u8) Self.Error![]const u8 {
        const actual = self.peek() orelse return error.EndOfBuffer;
        if (!std.mem.eql(u8, actual, token)) return error.InvalidToken;
        self.index += actual.len;
        return actual;
    }

    pub fn takeInt(self: *Self, comptime T: type) Self.Error!T {
        const token = self.peek() orelse return error.EndOfBuffer;
        const int = std.fmt.parseInt(T, token, 10) catch return error.InvalidToken;
        self.index += token.len;
        return int;
    }

    pub fn takeEnum(self: *Self, comptime T: type) Self.Error!T {
        const token = self.peek() orelse return error.EndOfBuffer;
        const e = std.meta.stringToEnum(T, token) orelse return error.InvalidToken;
        self.index += token.len;
        return e;
    }

    pub fn skipToken(self: *Self, token: []const u8) Self.Error!void {
        _ = try self.takeToken(token);
    }

    pub fn skipMany(self: *Self, amount: usize) Self.Error!void {
        for (0..amount) |_| try self.skip();
    }

    fn isDelimiter(self: *Self, char: u8) bool {
        return switch (char) {
            ' ', '\t', '\n' => true,
            '.', ',' => self.options.skip_punctuation,
            else => false,
        };
    }
};
