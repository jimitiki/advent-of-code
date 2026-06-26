const std = @import("std");
const lib = @import("lib");

const solver = lib.solver;
const Parser = lib.Parser;

const Vec3 = @Vector(3, i32);

const Particle = struct {
    id: u32,
    pos: Vec3,
    vel: Vec3,
    acc: Vec3,

    fn update(self: *Particle) void {
        self.vel += self.acc;
        self.pos += self.vel;
    }
};

// TODO: Fix part 1. It needs to break ties in the case where multiple particles have the minimum acceleration
// TODO: Speed up part 2

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?usize, ?usize } {
    var particle_list: std.ArrayList(Particle) = .empty;
    defer particle_list.deinit(tools.gpa);

    var id: u32 = 0;
    var reader = input.reader();
    while (try reader.takeDelimiter('\n')) |line| : (id += 1) {
        var parser: Parser = .init(line, .{});
        try particle_list.append(tools.gpa, .{
            .id = id,
            .pos = try parseVec(&parser),
            .vel = try parseVec(&parser),
            .acc = try parseVec(&parser),
        });
    }

    var min_acc: u32 = std.math.maxInt(u32);
    var particle_idx: ?usize = null;
    for (particle_list.items, 0..) |particle, idx| {
        const abs_acc: u32 = @reduce(.Add, @abs(particle.acc));
        if (abs_acc < min_acc) {
            min_acc = abs_acc;
            particle_idx = idx;
        }
    }

    var distances: std.AutoHashMapUnmanaged(struct { u32, u32 }, u32) = .empty;
    defer distances.deinit(tools.gpa);
    var closer: bool = true;
    var t: u32 = 0;
    while (closer) : (t += 1) {
        closer = false;
        for (particle_list.items) |*particle| particle.update();
        var i: usize = 0;
        while (i < particle_list.items.len - 1) {
            const a = particle_list.items[i];
            var j = i + 1;
            var collision = false;

            while (j < particle_list.items.len) {
                const b = particle_list.items[j];
                const d = dist(a, b);
                if (d == 0) {
                    collision = true;
                    _ = particle_list.swapRemove(j);
                } else {
                    const pair = .{ @min(a.id, b.id), @max(a.id, b.id) };
                    if (distances.get(pair)) |dprev| {
                        if (dprev > d) closer = true;
                    } else {
                        closer = true;
                    }
                    try distances.put(tools.gpa, pair, d);
                    j += 1;
                }
            }
            if (collision) {
                _ = particle_list.swapRemove(i);
            } else {
                i += 1;
            }
        }
    }
    return .{ particle_idx, particle_list.items.len };
}

pub const solve = solver.intSolver(usize, solveInt);

fn parseVec(parser: *Parser) Parser.Error!Vec3 {
    return .{
        try parser.findInt(i32),
        try parser.findInt(i32),
        try parser.findInt(i32),
    };
}

fn dist(a: Particle, b: Particle) u32 {
    return @reduce(.Add, @abs(a.pos - b.pos));
}
