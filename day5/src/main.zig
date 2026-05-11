const std = @import("std");

const Init = @import("lib").Init;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var ini = try Init.init(init, &stdout_buffer, &read_buffer);
    defer ini.deinit();

    var stdout = &ini.stdout_writer.interface;
    var input = &ini.input_reader.interface;

    //Handle ID ranges
    while (try input.takeDelimiter('\n')) |line| {
        if (line.len == 0) break;
        var split_point: usize = 0;
        while (line[split_point] != '-') : (split_point += 1) {}
        const start = try std.fmt.parseInt(u64, line[0..split_point], 10);
        const end = try std.fmt.parseInt(u64, line[split_point + 1 ..], 10);
        _ = start;
        _ = end;
    }

    // Handle IDs
    while (try input.takeDelimiter('\n')) |line| {
        const id = try std.fmt.parseInt(u64, line, 10);
        _ = id;
    }

    const answer = "";

    try stdout.print("{s}\n", .{answer});
    try stdout.flush();
}
