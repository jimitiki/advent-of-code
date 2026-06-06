const std = @import("std");

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
