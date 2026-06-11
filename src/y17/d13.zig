const std = @import("std");

const solver = @import("../solver.zig");
const expectIntSolution = @import("../test.zig").expectIntSolution;

const Layer = struct {
    depth: u32,
    range: u32,

    fn cycle(self: Layer) u32 {
        return (self.range - 1) * 2;
    }

    fn catches(self: Layer, start: u32) bool {
        return (self.depth + start) % self.cycle() == 0;
    }

    fn severity(self: Layer) u32 {
        return self.depth * self.range;
    }
};

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var firewall: std.ArrayList(Layer) = .empty;
    defer firewall.deinit(tools.gpa);

    while (try tools.input.takeDelimiter('\n')) |line| {
        for (line, 0..) |char, i| {
            if (char == ':') {
                const layer: Layer = .{
                    .depth = std.fmt.parseUnsigned(u32, line[0..i], 10) catch return error.InvalidInput,
                    .range = std.fmt.parseUnsigned(u32, line[i + 2 ..], 10) catch return error.InvalidInput,
                };
                try firewall.append(tools.gpa, layer);
                break;
            }
        }
    }

    var severity: u32 = 0;
    for (firewall.items) |layer| {
        if (layer.catches(0)) severity += layer.severity();
    }
    var start: u32 = 0;
    while (start < std.math.maxInt(u32)) : (start += 1) {
        for (firewall.items) |layer| {
            if (layer.catches(start)) break;
        } else {
            return .{ severity, start };
        }
    }
    return .{ severity, null };
}

pub const solve = solver.intSolver(u32, solveInt);

test "solve" {
    const input =
        \\0: 3
        \\1: 2
        \\4: 4
        \\6: 4
    ;
    try expectIntSolution(u32, solveInt, .{ 24, 10 }, input);
}
