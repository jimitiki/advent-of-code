const std = @import("std");

const solver = @import("../solver.zig");
const testing = @import("../testing.zig");

const Parser = @import("../Parser.zig");

const Vec2 = @Vector(2, i64);
const Light = struct {
    pos: Vec2,
    vel: Vec2,
};
const Rect = struct {
    x: i64,
    y: i64,
    h: u64,
    w: u64,

    fn area(self: Rect) u64 {
        return self.h * self.w;
    }
};

pub fn solve(input: solver.Input, tools: solver.Tools, _: *[32]u8, p2buf: *[32]u8) solver.Error!solver.Result {
    var light_list: std.ArrayList(Light) = .empty;
    defer light_list.deinit(tools.gpa);

    var lines = input.lines();
    while (lines.next()) |line| {
        var parser: Parser = .init(line, .{});
        try light_list.append(tools.gpa, .{
            .pos = .{ try parser.findInt(i64), try parser.findInt(i64) },
            .vel = .{ try parser.findInt(i64), try parser.findInt(i64) },
        });
    }

    var t: u16 = 0;
    var area: u64 = boundingBox(light_list.items).area();
    while (true) : (t += 1) {
        update(light_list.items);
        const a = boundingBox(light_list.items).area();
        if (a > area) break;
        area = a;
    }

    rewind(light_list.items);
    const box = boundingBox(light_list.items);
    for (0..box.h + 1) |i| {
        const y = box.y + @as(i64, @intCast(i));
        for (0..box.w + 1) |j| {
            const x = box.x + @as(i64, @intCast(j));
            const l = for (light_list.items) |light| {
                if (light.pos[0] == x and light.pos[1] == y) break true;
            } else false;
            const char: u8 = if (l) '#' else '.';
            try tools.stdout.printAsciiChar(char, .{});
        }
        try tools.stdout.writeAll("\n");
    }
    try tools.stdout.writeAll("\n");
    try tools.stdout.flush();

    return .{ "See console output", std.fmt.bufPrint(p2buf, "{}", .{t}) catch unreachable };
}

fn update(lights: []Light) void {
    for (lights) |*light| {
        light.pos += light.vel;
    }
}

fn rewind(lights: []Light) void {
    for (lights) |*light| {
        light.pos -= light.vel;
    }
}

fn boundingBox(lights: []const Light) Rect {
    var xmin: i64 = std.math.maxInt(i64);
    var xmax: i64 = std.math.minInt(i64);
    var ymin = xmin;
    var ymax = xmax;

    for (lights) |light| {
        xmin = @min(xmin, light.pos[0]);
        xmax = @max(xmax, light.pos[0]);
        ymin = @min(ymin, light.pos[1]);
        ymax = @max(ymax, light.pos[1]);
    }

    return .{
        .x = xmin,
        .y = ymin,
        .h = @intCast(@abs(ymax - ymin)),
        .w = @intCast(@abs(xmax - xmin)),
    };
}
