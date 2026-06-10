const std = @import("std");

const Parser = @import("Parser.zig");

pub const Result = struct { ?[]const u8, ?[]const u8 };
pub const Error = Parser.Error || error{ InvalidInput, OutOfMemory, ReadFailed, StreamTooLong, WriteFailed };

pub const InputType = enum { reader, file };
pub const Tools = struct {
    gpa: std.mem.Allocator,
    input: *std.Io.Reader,
    stdout: *std.Io.Writer,
    p1buf: *[32]u8,
    p2buf: *[32]u8,

    /// Reads the next line from the input stream, which is presumed to have only one line of
    /// useful data. If there is no line, `error.InvalidInput` is returned. Other read errors
    /// returned by the `Reader` itself are propagated.
    pub fn takeOneLine(self: Tools) error{ InvalidInput, ReadFailed, StreamTooLong }![]const u8 {
        return try self.input.takeDelimiter('\n') orelse error.InvalidInput;
    }
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
