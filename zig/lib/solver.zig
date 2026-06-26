const std = @import("std");

const Parser = @import("Parser.zig");

pub const Result = struct { ?[]const u8, ?[]const u8 };
pub const Error = Parser.Error || error{ InvalidInput, OutOfMemory, ReadFailed, StreamTooLong, WriteFailed };

pub const Input = struct {
    text: []const u8,

    pub const LineIterator = struct {
        buf: []const u8,
        index: usize = 0,

        pub fn next(self: *LineIterator) ?[]const u8 {
            if (self.index >= self.buf.len) return null;
            const start = self.index;
            var end = start;
            while (end < self.buf.len and self.buf[end] != '\n') : (end += 1) {}
            self.index = end + 1;
            return self.buf[start..end];
        }

        pub fn reset(self: *LineIterator) void {
            self.index = 0;
        }
    };

    pub fn reader(self: Input) std.Io.Reader {
        return std.Io.Reader.fixed(self.text);
    }

    pub fn parser(self: Input, options: Parser.Options) Parser {
        return .init(self.text, options);
    }

    pub fn lines(self: Input) LineIterator {
        return .{ .buf = self.text };
    }

    pub fn sliceLines(self: Input, gpa: std.mem.Allocator) error{OutOfMemory}![]const []const u8 {
        var count: usize = 0;
        var it: LineIterator = .{ .buf = self.text };
        while (it.next()) |_| : (count += 1) {}
        it.reset();

        const slice = try gpa.alloc([]const u8, count);

        var index: usize = 0;
        while (it.next()) |line| : (index += 1) {
            slice[index] = line;
        }
        return slice;
    }

    pub fn firstLine(self: Input) error{InvalidInput}![]const u8 {
        var l = self.lines();
        return l.next() orelse error.InvalidInput;
    }

    pub fn asInt(self: Input, comptime T: type) Parser.Error!T {
        var p = self.parser(.{});
        return try p.takeInt(T);
    }
};

pub const Tools = struct {
    gpa: std.mem.Allocator,
    stdout: *std.Io.Writer,
};
pub const Solver = *const fn (Input, Tools, *[32]u8, *[32]u8) Error!Result;
pub fn intSolver(comptime T: type, comptime solveFn: fn (Input, Tools) Error!struct { ?T, ?T }) Solver {
    switch (@typeInfo(T)) {
        .int => {},
        else => @compileError("Type must be an integer type, got" ++ @typeName(T)),
    }
    return struct {
        pub fn solve(input: Input, tools: Tools, p1buf: *[32]u8, p2buf: *[32]u8) Error!Result {
            const answers = try solveFn(input, tools);
            return .{ fmtIntAnswer(T, p1buf, answers[0]), fmtIntAnswer(T, p2buf, answers[1]) };
        }
    }.solve;
}

fn fmtIntAnswer(comptime T: type, buf: []u8, answer: ?T) ?[]const u8 {
    if (answer) |a| {
        return std.fmt.bufPrint(buf, "{}", .{a}) catch std.debug.panic("Answer too large: {}", .{a});
    } else {
        return null;
    }
}
