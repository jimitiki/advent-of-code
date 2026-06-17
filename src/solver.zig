const std = @import("std");

const Parser = @import("Parser.zig");

pub const Result = struct { ?[]const u8, ?[]const u8 };
pub const Error = Parser.Error || error{ InvalidInput, OutOfMemory, ReadFailed, StreamTooLong, WriteFailed };

pub const Input = struct {
    reader: *std.Io.Reader,
    text: []const u8,
    parser: Parser,

    pub fn takeOneLine(self: Input) error{ InvalidInput, ReadFailed, StreamTooLong }![]const u8 {
        return try self.reader.takeDelimiter('\n') orelse error.InvalidInput;
    }
};

pub const Tools = struct {
    gpa: std.mem.Allocator,
    input: Input,
    stdout: *std.Io.Writer,
    p1buf: *[32]u8,
    p2buf: *[32]u8,
};
pub const Solver = *const fn (Tools) Error!Result;
pub fn intSolver(comptime T: type, comptime solveFn: fn (Tools) Error!struct { ?T, ?T }) Solver {
    switch (@typeInfo(T)) {
        .int => {},
        else => @compileError("Type must be an integer type, got" ++ @typeName(T)),
    }
    return struct {
        pub fn solve(tools: Tools) Error!Result {
            const answers = try solveFn(tools);
            return .{ fmtIntAnswer(T, tools.p1buf, answers[0]), fmtIntAnswer(T, tools.p2buf, answers[1]) };
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
