const std = @import("std");

const lib = @import("lib");
const Boilerplate = lib.Boilerplate;
const Part = lib.Part;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [1]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();
    var stdout = &bp.stdout_writer.interface;
    try stdout.print("{}\n", .{try sumNumbers(bp.arena, &bp.input_reader.interface, bp.part == .p2)});
    try stdout.flush();
}

fn sumNumbers(allocator: std.mem.Allocator, reader: *std.Io.Reader, skip_red: bool) !i64 {
    var sum: i64 = 0;
    while (true) {
        const char = reader.peekByte() catch return sum;
        if (char == '-' or char >= '0' and char <= '9') {
            const num = try readNumber(allocator, reader);
            sum += num;
        } else {
            reader.seek += 1;
            switch (char) {
                '}' => {
                    return sum;
                },
                '{' => sum += try sumNumbers(allocator, reader, skip_red),
                ':' => if (skip_red and try checkRed(reader)) {
                    skipObject(reader);
                    return 0;
                },
                else => {},
            }
        }
    }
}

fn skipObject(reader: *std.Io.Reader) void {
    var depth: usize = 1;
    while (true) {
        const char = reader.takeByte() catch unreachable;
        switch (char) {
            '{' => depth += 1,
            '}' => {
                depth -= 1;
                if (depth == 0) return;
            },
            else => {},
        }
    }
}

fn readNumber(allocator: std.mem.Allocator, reader: *std.Io.Reader) !i64 {
    var chars: std.ArrayList(u8) = .empty;
    defer chars.deinit(allocator);
    try chars.append(allocator, try reader.takeByte());
    while (true) {
        const char = try reader.peekByte();
        if (char < '0' or char > '9') break;
        try chars.append(allocator, char);
        reader.seek += 1;
    }
    return std.fmt.parseInt(i64, chars.items, 10) catch error.InvalidInput;
}

fn checkRed(reader: *std.Io.Reader) !bool {
    for ("\"red\"") |expected| {
        const actual = try reader.peekByte();
        if (actual != expected) return false;
        reader.seek += 1;
    }
    return true;
}
