const std = @import("std");

const Boilerplate = @import("lib").Boilerplate;

const House = struct { x: i32, y: i32 };
const HouseSet = std.AutoHashMap(House, void);

// TODO: Create a visualization

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [1]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;

    var visited: std.AutoHashMapUnmanaged(House, void) = .empty;
    var x_santa: i32 = 0;
    var y_santa: i32 = 0;
    var x_robo: i32 = 0;
    var y_robo: i32 = 0;
    while (true) {
        try visited.put(bp.arena, .{ .x = x_santa, .y = y_santa }, {});
        if (input.takeByte()) |c| {
            switch (c) {
                '^' => y_santa += 1,
                'v' => y_santa -= 1,
                '>' => x_santa += 1,
                '<' => x_santa -= 1,
                '\n' => break,
                else => return error.InvalidInput,
            }
        } else |_| break;
        if (bp.part == .p2) {
            try visited.put(bp.arena, .{ .x = x_robo, .y = y_robo }, {});
            if (input.takeByte()) |c| {
                switch (c) {
                    '^' => y_robo += 1,
                    'v' => y_robo -= 1,
                    '>' => x_robo += 1,
                    '<' => x_robo -= 1,
                    '\n' => break,
                    else => return error.InvalidInput,
                }
            } else |_| break;
        }
    }
    while (try input.takeDelimiter('\n')) |line| {
        _ = line;
    }
    const answer = visited.size;

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}
