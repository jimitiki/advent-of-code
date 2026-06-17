const std = @import("std");

const solver = @import("../solver.zig");
const t = @import("../test.zig");
const Parser = @import("../Parser.zig");

const Op = enum {
    inc,
    dec,

    fn resolve(self: Op, a: i32, b: i32) i32 {
        return switch (self) {
            .inc => a + b,
            .dec => a - b,
        };
    }
};
const Cmp = enum {
    @"<",
    @"<=",
    @"==",
    @">=",
    @">",
    @"!=",

    pub fn resolve(self: Cmp, a: i32, b: i32) bool {
        const op = switch (self) {
            .@"<" => std.math.CompareOperator.lt,
            .@"<=" => std.math.CompareOperator.lte,
            .@"==" => std.math.CompareOperator.eq,
            .@">=" => std.math.CompareOperator.gte,
            .@">" => std.math.CompareOperator.gt,
            .@"!=" => std.math.CompareOperator.neq,
        };
        return std.math.compare(a, op, b);
    }
};

fn solveInt(tools: solver.Tools) solver.Error!struct { ?i32, ?i32 } {
    var registers: std.AutoHashMapUnmanaged(u32, i32) = .empty;
    defer registers.deinit(tools.gpa);

    var max_during: i32 = 0;
    while (try tools.input.reader.takeDelimiter('\n')) |line| {
        var parser: Parser = .init(line, .{});
        const target = try parser.take();
        const op = try parser.takeEnum(Op);
        const amt = try parser.takeInt(i32);
        _ = try parser.skipToken("if");
        const cmp_reg = convert(try parser.take());
        const cmp = try parser.takeEnum(Cmp);
        const value = try parser.takeInt(i32);

        if (cmp.resolve(registers.get(cmp_reg) orelse 0, value)) {
            const entry = try registers.getOrPutValue(tools.gpa, convert(target), 0);
            entry.value_ptr.* = op.resolve(entry.value_ptr.*, amt);
            max_during = @max(max_during, entry.value_ptr.*);
        }
        // const dest_id = convert(try parser.take());
    }
    var max_after: i32 = std.math.minInt(i32);
    var it = registers.valueIterator();
    while (it.next()) |v| max_after = @max(v.*, max_after);
    return .{ max_after, max_during };
}

pub const solve = solver.intSolver(i32, solveInt);

test "solve" {
    const input =
        \\b inc 5 if a > 1
        \\a inc 1 if b < 5
        \\c dec -10 if a >= 1
        \\c inc -20 if c == 10
    ;
    try t.expectIntSolution(i32, solveInt, .{ 1, 10 }, input);
}

fn convert(name: []const u8) u32 {
    std.debug.assert(name.len < 4);
    var id: u32 = 0;
    for (name, 0..) |char, i| {
        id |= @as(u32, char) << @as(u5, @intCast((name.len - i - 1) * 8));
        // std.debug.print("{} -> ", .{id});
    }
    return id;
}
