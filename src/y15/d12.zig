const std = @import("std");

const solver = @import("../solver.zig");

fn solveInt(gpa: std.mem.Allocator, reader: *std.Io.Reader) solver.Error!struct { ?i64, ?i64 } {
    const answer = try sumNumbers(gpa, reader);
    return .{ answer[0], answer[1] };
}

pub const solve = solver.intSolver(i64, solveInt);

fn sumNumbers(allocator: std.mem.Allocator, reader: *std.Io.Reader) solver.Error!struct { i64, i64 } {
    var sum: i64 = 0;
    var red_sum: i64 = 0;
    var red = false;
    while (true) {
        const char = reader.peekByte() catch return .{ sum, if (red) 0 else red_sum };
        if (char == '-' or char >= '0' and char <= '9') {
            const num = try readNumber(allocator, reader);
            sum += num;
            red_sum += num;
        } else {
            reader.seek += 1;
            switch (char) {
                '}' => return .{ sum, if (red) 0 else red_sum },
                '{' => {
                    const result = try sumNumbers(allocator, reader);
                    sum += result[0];
                    red_sum += result[1];
                },
                ':' => if (try checkRed(reader)) {
                    red = true;
                },
                else => {},
            }
        }
    }
}

fn readNumber(allocator: std.mem.Allocator, reader: *std.Io.Reader) solver.Error!i64 {
    var chars: std.ArrayList(u8) = .empty;
    defer chars.deinit(allocator);
    chars.append(allocator, reader.takeByte() catch return error.InvalidInput) catch unreachable;
    while (true) {
        const char = reader.peekByte() catch return error.InvalidInput;
        if (char < '0' or char > '9') break;
        chars.append(allocator, char) catch unreachable;
        reader.seek += 1;
    }
    return std.fmt.parseInt(i64, chars.items, 10) catch error.InvalidInput;
}

fn checkRed(reader: *std.Io.Reader) solver.Error!bool {
    for ("\"red\"") |expected| {
        const actual = reader.peekByte() catch return error.InvalidInput;
        if (actual != expected) return false;
        reader.seek += 1;
    }
    return true;
}
