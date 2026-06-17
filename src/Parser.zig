const Parser = @This();
const std = @import("std");

buf: []const u8,
index: usize = 0,
options: Options = .{},

pub const Options = struct {
    skip_punctuation: bool = true,
};

pub const TakeError = error{EndOfBuffer};
pub const TokenError = error{InvalidToken};
pub const Error = TakeError || TokenError;

pub fn init(buf: []const u8, options: Options) Parser {
    return .{ .buf = buf, .options = options };
}

pub fn peek(self: *Parser) ?[]const u8 {
    while (self.index < self.buf.len and self.isDelimiter(self.buf[self.index])) : (self.index += 1) {}
    if (self.index >= self.buf.len) {
        return null;
    }

    var end = self.index;
    while (end < self.buf.len and !self.isDelimiter(self.buf[end])) : (end += 1) {}
    return self.buf[self.index..end];
}

pub fn take(self: *Parser) Parser.TakeError![]const u8 {
    const token = self.peek() orelse return error.EndOfBuffer;
    self.index += token.len;
    return token;
}

pub fn skip(self: *Parser) Parser.TakeError!void {
    _ = try self.take();
}

pub fn parseInt(self: *Parser, comptime T: type) TokenError!?T {
    const token = self.peek() orelse return null;
    const int = std.fmt.parseInt(T, token, 10) catch return error.InvalidToken;
    self.index += token.len;
    return int;
}

pub fn takeByte(self: *Parser) Parser.Error!u8 {
    const token = self.peek() orelse return error.EndOfBuffer;
    if (token.len != 1) return error.InvalidToken;
    self.index += token.len;
    return token[0];
}

pub fn takeToken(self: *Parser, token: []const u8) Parser.Error![]const u8 {
    const actual = self.peek() orelse return error.EndOfBuffer;
    if (!std.mem.eql(u8, actual, token)) return error.InvalidToken;
    self.index += actual.len;
    return actual;
}

pub fn takeInt(self: *Parser, comptime T: type) Parser.Error!T {
    return (try self.parseInt(T)) orelse error.EndOfBuffer;
}

pub fn takeEnum(self: *Parser, comptime T: type) Parser.Error!T {
    const token = self.peek() orelse return error.EndOfBuffer;
    const e = std.meta.stringToEnum(T, token) orelse return error.InvalidToken;
    self.index += token.len;
    return e;
}

pub fn findInt(self: *Parser, comptime T: type) Parser.Error!T {
    const incl_neg = @typeInfo(T).int.signedness == .signed;
    while (self.index < self.buf.len and !self.isInt(incl_neg)) : (self.index += 1) {}
    if (self.index == self.buf.len) {
        return error.EndOfBuffer;
    }

    const start = self.index;
    self.index += 1;
    while (self.index < self.buf.len and self.buf[self.index] >= '0' and self.buf[self.index] <= '9') : (self.index += 1) {}
    if (std.fmt.parseInt(T, self.buf[start..self.index], 10)) |i| {
        return i;
    } else |err| {
        switch (err) {
            error.InvalidCharacter => unreachable,
            error.Overflow => return error.InvalidToken,
        }
    }
}

pub fn skipToken(self: *Parser, token: []const u8) Parser.Error!void {
    _ = try self.takeToken(token);
}

pub fn skipMany(self: *Parser, amount: usize) Parser.Error!void {
    for (0..amount) |_| try self.skip();
}

fn isDelimiter(self: *Parser, char: u8) bool {
    return switch (char) {
        ' ', '\t', '\n' => true,
        '.', ',' => self.options.skip_punctuation,
        else => false,
    };
}

fn isInt(self: Parser, incl_neg: bool) bool {
    if (self.buf[self.index] == '-') {
        if (!incl_neg) return false;
        if (self.index == self.buf.len - 1) return false;

        const next = self.buf[self.index + 1];
        return next >= '0' and next <= '9';
    }
    return self.buf[self.index] >= '0' and self.buf[self.index] <= '9';
}
