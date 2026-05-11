const std = @import("std");

const Init = @import("lib").Init;

const ArrayList = std.ArrayList;
const OperandRow = std.ArrayList(u64);

const Op = enum {
    add,
    mult,
};

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [4096]u8 = undefined;
    var ini = try Init.init(init, &stdout_buffer, &read_buffer);
    defer ini.deinit();

    var stdout = &ini.stdout_writer.interface;
    var input = &ini.input_reader.interface;

    var count: usize = 0;
    var operand_tbl: ArrayList(OperandRow) = .empty;
    var operators: ArrayList(Op) = undefined;
    while (try input.takeDelimiter('\n')) |line| {
        if (line[0] == '+' or line[0] == '*') {
            // Read final line of operators
            operators = try .initCapacity(ini.arena, count);
            for (line) |char| {
                switch (char) {
                    '+' => try operators.append(ini.arena, .add),
                    '*' => try operators.append(ini.arena, .mult),
                    ' ' => {},
                    else => unreachable,
                }
            }
        } else {
            // Read row of operands
            var row: OperandRow = try .initCapacity(ini.arena, count);
            var start: usize = 0;
            var reading: bool = false;
            for (line, 0..) |char, i| {
                if (char == ' ') {
                    if (reading) {
                        reading = false;
                        try row.append(ini.arena, try std.fmt.parseInt(u64, line[start..i], 10));
                    }
                } else if (char >= '0' and char <= '9') {
                    if (!reading) {
                        start = i;
                        reading = true;
                    }
                } else {
                    unreachable;
                }
            }
            if (reading) {
                try row.append(ini.arena, try std.fmt.parseInt(u64, line[start..], 10));
            }
            try operand_tbl.append(ini.arena, row);
            if (count == 0) count = row.items.len;
        }
    }

    var answer: u64 = 0;
    for (operators.items, 0..) |op, i| {
        switch (op) {
            .add => {
                var sum: u64 = 0;
                for (operand_tbl.items) |row| {
                    sum += row.items[i];
                }
                answer += sum;
            },
            .mult => {
                var product: u64 = 1;
                for (operand_tbl.items) |row| {
                    product *= row.items[i];
                }
                answer += product;
            },
        }
    }

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}
