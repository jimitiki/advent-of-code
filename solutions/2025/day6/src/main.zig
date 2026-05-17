const std = @import("std");

const Boilerplate = @import("boilerplate").Boilerplate;

const ArrayList = std.ArrayList;
const OperandRow = std.ArrayList(u64);

const Op = enum {
    add,
    mult,
};

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [4096]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    const solution = if (bp.part == .p1) &computeHorizontal else &computeVertical;

    const answer = try solution(bp.arena, &bp.input_reader.interface);
    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn computeHorizontal(alloc: std.mem.Allocator, input: *std.Io.Reader) !u64 {
    var count: usize = 0;
    var operand_tbl: ArrayList(OperandRow) = .empty;
    var operators: ArrayList(Op) = undefined;
    while (try input.takeDelimiter('\n')) |line| {
        if (line[0] == '+' or line[0] == '*') {
            // Read final line of operators
            operators = try .initCapacity(alloc, count);
            for (line) |char| {
                switch (char) {
                    '+' => try operators.append(alloc, .add),
                    '*' => try operators.append(alloc, .mult),
                    ' ' => {},
                    else => unreachable,
                }
            }
        } else {
            // Read row of operands
            var row: OperandRow = try .initCapacity(alloc, count);
            var start: usize = 0;
            var reading: bool = false;
            for (line, 0..) |char, i| {
                if (char == ' ') {
                    if (reading) {
                        reading = false;
                        try row.append(alloc, try std.fmt.parseInt(u64, line[start..i], 10));
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
                try row.append(alloc, try std.fmt.parseInt(u64, line[start..], 10));
            }
            try operand_tbl.append(alloc, row);
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
    return answer;
}

fn computeVertical(alloc: std.mem.Allocator, input: *std.Io.Reader) !u64 {
    var count: usize = 0;
    var text: ArrayList(ArrayList(u8)) = .empty;
    while (try input.takeDelimiter('\n')) |line| {
        if (count == 0) count = line.len;
        if (line.len != count) return error.InvalidInput;
        var row: ArrayList(u8) = .empty;
        try row.appendSlice(alloc, line);
        try text.append(alloc, row);
    }

    var answer: u64 = 0;
    var acc: u64 = 0;
    var op: Op = undefined;
    var digits: []u8 = try alloc.alloc(u8, text.items.len - 1);
    for (0..count) |col| {
        switch (text.items[text.items.len - 1].items[col]) {
            '+' => op = .add,
            '*' => op = .mult,
            ' ' => {},
            else => unreachable,
        }
        var digit_cnt: usize = 0;
        for (text.items[0 .. text.items.len - 1]) |row| {
            if (row.items[col] >= '1' and row.items[col] <= '9') {
                digits[digit_cnt] = row.items[col];
                digit_cnt += 1;
            }
        }
        if (digit_cnt > 0) {
            const operand = try std.fmt.parseUnsigned(u64, digits[0..digit_cnt], 10);
            acc = switch (op) {
                .add => acc + operand,
                .mult => if (acc == 0) operand else acc * operand,
            };
        }
        if (digit_cnt == 0 or col == count - 1) {
            answer += acc;
            acc = 0;
        }
    }
    return answer;
}
