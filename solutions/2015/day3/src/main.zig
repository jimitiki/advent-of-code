const std = @import("std");

const Boilerplate = @import("boilerplate").Boilerplate;

const House = struct { x: i32, y: i32 };
const HouseSet = std.AutoHashMap(House, void);

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [1]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;

    var visited: std.AutoHashMapUnmanaged(House, void) = .empty;
    var x: i32 = 0;
    var y: i32 = 0;
    while (true) {
        try visited.put(bp.arena, .{ .x = x, .y = y }, {});
        if (input.takeByte()) |c| {
            switch (c) {
                '^' => y += 1,
                'v' => y -= 1,
                '>' => x += 1,
                '<' => x -= 1,
                '\n' => break,
                else => return error.InvalidInput,
            }
        } else |_| break;
    }
    while (try input.takeDelimiter('\n')) |line| {
        _ = line;
    }
    const answer = visited.size;

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}
