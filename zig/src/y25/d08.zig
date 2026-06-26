const std = @import("std");
const lib = @import("lib");

const Order = std.math.Order;
const Circuit = std.array_hash_map.Auto(Pos, void);

const solver = lib.solver;

const Pos = struct { u32, u32, u32 };

const Pair = struct {
    a: Pos,
    b: Pos,
    dist: f32,

    pub fn init(a: Pos, b: Pos) Pair {
        const dx = @as(i64, a[0]) - @as(i64, b[0]);
        const dy = @as(i64, a[1]) - @as(i64, b[1]);
        const dz = @as(i64, a[2]) - @as(i64, b[2]);
        return .{
            .a = a,
            .b = b,
            .dist = @sqrt(@floatFromInt(dx * dx + dy * dy + dz * dz)),
        };
    }

    pub fn lessThan(_: void, lhs: Pair, rhs: Pair) bool {
        return (lhs.dist < rhs.dist);
    }
};

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?usize, ?usize } {
    const gpa = tools.gpa;
    var pairs: std.ArrayList(Pair) = .empty;
    defer pairs.deinit(gpa);
    var boxes: std.ArrayList(Pos) = .empty;
    defer boxes.deinit(gpa);

    // Find closest pairs
    var reader = input.reader();
    while (try reader.takeDelimiter('\n')) |line| {
        var endx: usize = 0;
        const pos: Pos = for (line, 0..) |c, i| {
            if (c == ',') {
                if (endx == 0) {
                    endx = i;
                } else {
                    break .{
                        std.fmt.parseUnsigned(u32, line[0..endx], 10) catch return error.InvalidInput,
                        std.fmt.parseUnsigned(u32, line[endx + 1 .. i], 10) catch return error.InvalidInput,
                        std.fmt.parseUnsigned(u32, line[i + 1 ..], 10) catch return error.InvalidInput,
                    };
                }
            }
        } else unreachable;
        for (boxes.items) |p| {
            try pairs.append(gpa, .init(pos, p));
        }
        try boxes.append(gpa, pos);
    }
    std.sort.pdq(Pair, pairs.items, {}, Pair.lessThan);

    var circuits: std.ArrayList(Circuit) = .empty;
    defer {
        for (circuits.items) |*circuit| circuit.deinit(gpa);
        circuits.deinit(gpa);
    }
    var answer1: ?u64 = null;
    var answer2: ?u64 = null;
    for (pairs.items, 0..) |pair, j| {
        const ia: ?usize = for (circuits.items, 0..) |circuit, i| {
            if (circuit.contains(pair.a)) break i;
        } else null;
        const ib: ?usize = for (circuits.items, 0..) |circuit, i| {
            if (circuit.contains(pair.b)) break i;
        } else null;

        if (ia) |ca| {
            if (ib) |cb| {
                if (ia != ib) {
                    try circuits.items[ca].ensureUnusedCapacity(gpa, circuits.items[cb].entries.len);
                    for (circuits.items[cb].keys()) |p| try circuits.items[ca].put(gpa, p, {});
                    circuits.items[cb].deinit(gpa);
                    _ = circuits.swapRemove(cb);
                }
            } else {
                try circuits.items[ca].put(gpa, pair.b, {});
            }
        } else if (ib) |cb| {
            try circuits.items[cb].put(gpa, pair.a, {});
        } else {
            var circuit: Circuit = .empty;
            try circuit.put(gpa, pair.a, {});
            try circuit.put(gpa, pair.b, {});
            try circuits.append(gpa, circuit);
        }
        if (j == 1000) {
            std.sort.pdq(Circuit, circuits.items, {}, cmpCircuit);
            answer1 = circuits.items[0].entries.len * circuits.items[1].entries.len * circuits.items[2].entries.len;
        }
        if (circuits.items.len == 1 and circuits.items[0].entries.len == boxes.items.len) {
            answer2 = pair.a[0] * pair.b[0];
            break;
        }
    }

    return .{ answer1, answer2 };
}

pub const solve = solver.intSolver(usize, solveInt);

fn cmpCircuit(_: void, lhs: Circuit, rhs: Circuit) bool {
    return lhs.entries.len > rhs.entries.len;
}
