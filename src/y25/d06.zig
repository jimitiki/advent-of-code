const std = @import("std");

const solver = @import("../solver.zig");
const Boilerplate = @import("lib").Boilerplate;

const ArrayList = std.ArrayList;
const OperandRow = std.ArrayList(u64);

const Op = enum {
    add,
    mult,
};

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u64, ?u64 } {
    const gpa = tools.gpa;
    var lines: std.ArrayList([]const u8) = .empty;
    defer {
        for (lines.items) |line| gpa.free(line);
        lines.deinit(gpa);
    }
    while (try input.reader.takeDelimiter('\n')) |line| {
        if (lines.items.len > 0 and line.len != lines.items[0].len) {
            return error.InvalidInput;
        }
        const l = try gpa.alloc(u8, line.len);
        @memcpy(l, line);
        try lines.append(gpa, l);
    }
    return .{
        try computeHorizontal(gpa, lines.items),
        try computeVertical(gpa, lines.items),
    };
}

pub const solve = solver.intSolver(u64, solveInt);

fn computeHorizontal(alloc: std.mem.Allocator, lines: []const []const u8) solver.Error!u64 {
    var count: usize = 0;
    var operand_tbl: ArrayList(OperandRow) = .empty;
    defer {
        for (operand_tbl.items) |*operands| {
            operands.deinit(alloc);
        }
        operand_tbl.deinit(alloc);
    }
    var operators: ArrayList(Op) = .empty;
    defer operators.deinit(alloc);
    for (lines) |line| {
        if (line[0] == '+' or line[0] == '*') {
            // Read final line of operators
            try operators.ensureTotalCapacity(alloc, count);
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
                        try row.append(alloc, std.fmt.parseInt(u64, line[start..i], 10) catch return error.InvalidInput);
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
                try row.append(alloc, std.fmt.parseInt(u64, line[start..], 10) catch return error.InvalidInput);
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

fn computeVertical(alloc: std.mem.Allocator, lines: []const []const u8) solver.Error!u64 {
    var answer: u64 = 0;
    var acc: u64 = 0;
    var op: Op = undefined;
    var digits: []u8 = try alloc.alloc(u8, lines.len - 1);
    defer alloc.free(digits);
    for (0..lines[0].len) |col| {
        switch (lines[lines.len - 1][col]) {
            '+' => op = .add,
            '*' => op = .mult,
            ' ' => {},
            else => unreachable,
        }
        var digit_cnt: usize = 0;
        for (lines[0 .. lines.len - 1]) |row| {
            if (row[col] >= '1' and row[col] <= '9') {
                digits[digit_cnt] = row[col];
                digit_cnt += 1;
            }
        }
        if (digit_cnt > 0) {
            const operand = std.fmt.parseUnsigned(u64, digits[0..digit_cnt], 10) catch return error.InvalidInput;
            acc = switch (op) {
                .add => acc + operand,
                .mult => if (acc == 0) operand else acc * operand,
            };
        }
        if (digit_cnt == 0 or col == lines[0].len - 1) {
            answer += acc;
            acc = 0;
        }
    }
    return answer;
}
