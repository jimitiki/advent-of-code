const std = @import("std");

const Init = @import("lib").Init;

const digits = "987654321";

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [64]u8 = undefined;
    var read_buffer: [128]u8 = undefined;
    var ini = try Init.init(init, &stdout_buffer, &read_buffer);
    defer ini.deinit();

    var stdout = &ini.stdout_writer.interface;
    var input = &ini.input_reader.interface;
    var answer: u64 = 0;
    while (try input.takeDelimiter('\n')) |line| {
        answer += try highestJoltage(line, 2);
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn highestJoltage(bank: []u8, battery_cnt: u8) !u64 {
    var digit_buf: [128]u8 = undefined;
    var min_idx: usize = 0;
    for (0..battery_cnt) |jolt_idx| {
        for (digits) |digit| {
            const subbank = bank[min_idx .. bank.len - (battery_cnt - jolt_idx) + 1];
            if (findBattery(subbank, digit)) |battery_idx| {
                digit_buf[jolt_idx] = digit;
                min_idx = min_idx + battery_idx + 1;
                break;
            }
        }
    }
    return try std.fmt.parseInt(u64, digit_buf[0..battery_cnt], 10);
}

fn findBattery(bank: []u8, joltage: u8) ?usize {
    for (bank, 0..) |battery, i| {
        if (battery == joltage) return i;
    }
    return null;
}
