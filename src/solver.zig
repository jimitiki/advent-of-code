const std = @import("std");

const Parser = @import("Parser.zig");

pub const Result = struct { ?[]const u8, ?[]const u8 };
pub const Error = Parser.Error || error{ InvalidInput, OutOfMemory, ReadFailed, StreamTooLong, WriteFailed };

pub const Input = struct {
    text: []const u8,

    pub fn reader(self: Input) std.Io.Reader {
        return std.Io.Reader.fixed(self.text);
    }

    pub fn parser(self: Input, options: Parser.Options) Parser {
        return .init(self.text, options);
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
