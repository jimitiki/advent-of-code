const std = @import("std");

pub const Result = struct { ?[]const u8, ?[]const u8 };
pub const Error = error{ InvalidInput, OutOfMemory, ReadFailed, StreamTooLong, TooManyWords };

pub const InputType = enum { reader, file };
pub const Solver = *const fn (std.mem.Allocator, *std.Io.Reader, []u8, []u8) Error!Result;
pub fn intSolver(comptime T: type, comptime solveFn: fn (std.mem.Allocator, *std.Io.Reader) Error!struct { ?T, ?T }) Solver {
    switch (@typeInfo(T)) {
        .int => {},
        else => @compileError("Type must be an integer type, got" ++ @typeName(T)),
    }
    return struct {
        pub fn solve(gpa: std.mem.Allocator, reader: *std.Io.Reader, buf1: []u8, buf2: []u8) Error!Result {
            const result = try solveFn(gpa, reader);
            return .{ fmtIntAnswer(T, buf1, result[0]), fmtIntAnswer(T, buf2, result[1]) };
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
