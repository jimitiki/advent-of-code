const std = @import("std");

const solver = @import("../solver.zig");

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    _ = tools;
    return try analyzeStream(input.reader);
}

fn analyzeStream(reader: *std.Io.Reader) error{ReadFailed}!struct { u16, u16 } {
    var depth: u8 = 0;
    var score: u16 = 0;
    var in_garbage = false;
    var garbage_count: u16 = 0;
    while (true) {
        const c = reader.takeByte() catch break;
        switch (c) {
            '!' => _ = try reader.discardShort(1),
            '>' => in_garbage = false,
            '<' => {
                if (in_garbage) {
                    garbage_count += 1;
                } else {
                    in_garbage = true;
                }
            },
            '{' => {
                if (!in_garbage) {
                    depth += 1;
                    score += depth;
                } else {
                    garbage_count += 1;
                }
            },
            '}' => {
                if (!in_garbage) {
                    depth -= 1;
                } else {
                    garbage_count += 1;
                }
            },
            else => {
                if (in_garbage) {
                    garbage_count += 1;
                }
            },
        }
    }
    return .{ score, garbage_count };
}

pub const solve = solver.intSolver(u16, solveInt);

test "score" {
    {
        const text = "{}";
        var input = std.Io.Reader.fixed(text);
        try std.testing.expectEqual(1, (try analyzeStream(&input))[0]);
    }
    {
        const text = "{{{}}}";
        var input = std.Io.Reader.fixed(text);
        try std.testing.expectEqual(6, (try analyzeStream(&input))[0]);
    }
    {
        const text = "{{},{}}";
        var input = std.Io.Reader.fixed(text);
        try std.testing.expectEqual(5, (try analyzeStream(&input))[0]);
    }
    {
        const text = "{{{},{},{{}}}}";
        var input = std.Io.Reader.fixed(text);
        try std.testing.expectEqual(16, (try analyzeStream(&input))[0]);
    }
    {
        const text = "{<a>,<a>,<a>,<a>}";
        var input = std.Io.Reader.fixed(text);
        try std.testing.expectEqual(1, (try analyzeStream(&input))[0]);
    }
    {
        const text = "{{<ab>},{<ab>},{<ab>},{<ab>}}";
        var input = std.Io.Reader.fixed(text);
        try std.testing.expectEqual(9, (try analyzeStream(&input))[0]);
    }
    {
        const text = "{{<!!>},{<!!>},{<!!>},{<!!>}}";
        var input = std.Io.Reader.fixed(text);
        try std.testing.expectEqual(9, (try analyzeStream(&input))[0]);
    }
    {
        const text = "{{<a!>},{<a!>},{<a!>},{<ab>}}";
        var input = std.Io.Reader.fixed(text);
        try std.testing.expectEqual(3, (try analyzeStream(&input))[0]);
    }
}

test "count garbage" {
    {
        const text = "<>";
        var input = std.Io.Reader.fixed(text);
        try std.testing.expectEqual(0, (try analyzeStream(&input))[1]);
    }
    {
        const text = "<random characters>";
        var input = std.Io.Reader.fixed(text);
        try std.testing.expectEqual(17, (try analyzeStream(&input))[1]);
    }
    {
        const text = "<<<<>";
        var input = std.Io.Reader.fixed(text);
        try std.testing.expectEqual(3, (try analyzeStream(&input))[1]);
    }
    {
        const text = "<{!>}>";
        var input = std.Io.Reader.fixed(text);
        try std.testing.expectEqual(2, (try analyzeStream(&input))[1]);
    }
    {
        const text = "<!!>";
        var input = std.Io.Reader.fixed(text);
        try std.testing.expectEqual(0, (try analyzeStream(&input))[1]);
    }
    {
        const text = "<!!!>>";
        var input = std.Io.Reader.fixed(text);
        try std.testing.expectEqual(0, (try analyzeStream(&input))[1]);
    }
    {
        const text = "<{o\"i!a,<{i<a>";
        var input = std.Io.Reader.fixed(text);
        try std.testing.expectEqual(10, (try analyzeStream(&input))[1]);
    }
}
