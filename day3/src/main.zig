const std = @import("std");

const Init = @import("lib").Init;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var ini = try Init.init(init, &stdout_buffer, &read_buffer);
    defer ini.deinit();

    var stdout = &ini.stdout_writer.interface;
    var input = &ini.input_reader.interface;
    var answer: u32 = 0;
    while (try input.takeDelimiter('\n')) |line| {
        answer += highestJoltage(line);
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn highestJoltage(bank: []u8) u8 {
    var tens: u8 = '9';
    while (tens >= '1') : (tens -= 1) {
        const tidx = if (findBattery(bank, tens)) |idx| idx else continue;
        var ones: u8 = '9';
        while (ones >= '1') : (ones -= 1) {
            if (findBattery(bank[tidx + 1 ..], ones)) |_| {} else continue;
            return digitsToInt(tens, ones);
        }
    }
    return 0;
}

fn findBattery(bank: []u8, joltage: u8) ?usize {
    for (bank, 0..) |battery, i| {
        if (battery == joltage) return i;
    }
    return null;
}

fn digitsToInt(digit1: u8, digit2: u8) u8 {
    return (digit1 - 48) * 10 + digit2 - 48;
}
