const std = @import("std");

const Init = @import("lib").Init;

const Order = std.math.Order;
const Circuit = std.array_hash_map.Auto(Pos, void);

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

    pub fn cmp(_: void, lhs: Pair, rhs: Pair) Order {
        if (lhs.dist < rhs.dist) {
            return Order.lt;
        } else if (lhs.dist > rhs.dist) {
            return Order.gt;
        } else {
            return Order.eq;
        }
    }
};

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var ini = try Init.init(init, &stdout_buffer, &read_buffer);
    defer ini.deinit();

    var stdout = &ini.stdout_writer.interface;
    var input = &ini.input_reader.interface;

    var closest_pairs: std.PriorityDequeue(Pair, void, Pair.cmp) = .initContext({});
    defer closest_pairs.deinit(ini.arena);
    try closest_pairs.ensureTotalCapacity(ini.arena, 1001);
    var boxes: std.ArrayList(Pos) = .empty;
    defer boxes.deinit(ini.arena);

    // Find closest pairs
    while (try input.takeDelimiter('\n')) |line| {
        var endx: usize = 0;
        const pos: Pos = for (line, 0..) |c, i| {
            if (c == ',') {
                if (endx == 0) {
                    endx = i;
                } else {
                    break .{
                        try std.fmt.parseUnsigned(u32, line[0..endx], 10),
                        try std.fmt.parseUnsigned(u32, line[endx + 1 .. i], 10),
                        try std.fmt.parseUnsigned(u32, line[i + 1 ..], 10),
                    };
                }
            }
        } else unreachable;
        for (boxes.items) |p| {
            try closest_pairs.push(ini.arena, .init(pos, p));
            if (closest_pairs.len > 1000) _ = closest_pairs.popMax();
        }
        try boxes.append(ini.arena, pos);
    }

    var circuits: std.ArrayList(Circuit) = .empty;
    while (closest_pairs.popMin()) |pair| {
        const ia: ?usize = for (circuits.items, 0..) |circuit, i| {
            if (circuit.contains(pair.a)) break i;
        } else null;
        const ib: ?usize = for (circuits.items, 0..) |circuit, i| {
            if (circuit.contains(pair.b)) break i;
        } else null;
        if (ia) |ca| {
            if (ib) |cb| {
                if (ia == ib) continue;
                try circuits.items[ca].ensureUnusedCapacity(ini.arena, circuits.items[cb].entries.len);
                for (circuits.items[cb].keys()) |p| try circuits.items[ca].put(ini.arena, p, {});
                circuits.items[cb].deinit(ini.arena);
                _ = circuits.swapRemove(cb);
            } else {
                try circuits.items[ca].put(ini.arena, pair.b, {});
            }
        } else if (ib) |cb| {
            try circuits.items[cb].put(ini.arena, pair.a, {});
        } else {
            var circuit: Circuit = .empty;
            try circuit.put(ini.arena, pair.a, {});
            try circuit.put(ini.arena, pair.b, {});
            try circuits.append(ini.arena, circuit);
        }
    }
    std.sort.pdq(Circuit, circuits.items, {}, cmpCircuit);
    const answer = circuits.items[0].entries.len * circuits.items[1].entries.len * circuits.items[2].entries.len;

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn cmpCircuit(_: void, lhs: Circuit, rhs: Circuit) bool {
    return lhs.entries.len > rhs.entries.len;
}
