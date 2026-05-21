const std = @import("std");

const lib = @import("lib");
const Boilerplate = lib.Boilerplate;
const WordIterator = lib.parse.WordIterator;

const NameSet = std.StringArrayHashMapUnmanaged(void);
const HappinessTable = std.StringHashMapUnmanaged(i16);
const RelativeTable = std.StringHashMapUnmanaged(HappinessTable);

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;
    var names: NameSet = .empty;
    defer {
        for (names.keys()) |name| {
            bp.arena.free(name);
        }
        names.deinit(bp.arena);
    }
    var relatives: RelativeTable = .empty;
    defer {
        var it = relatives.valueIterator();
        while (it.next()) |value| {
            value.deinit(bp.arena);
        }
        relatives.deinit(bp.arena);
    }
    while (try input.takeDelimiter('\n')) |line| {
        var it = WordIterator.init(line[0 .. line.len - 1]);
        const name1 = it.next().?;
        _ = it.next().?;
        const mod = it.next().?;
        const points = try std.fmt.parseInt(i16, it.next().?, 10);
        for (0..6) |_| _ = it.next().?;
        const name2 = it.next().?;

        const rel1 = try addName(bp.arena, &names, name1);
        const rel2 = try addName(bp.arena, &names, name2);
        try addOpinion(bp.arena, &relatives, rel1, rel2, mod, points);
    }

    const seating = try bp.arena.alloc([]const u8, names.count());
    seating[0] = names.keys()[0];
    var unseated: NameSet = try names.clone(bp.arena);
    _ = unseated.swapRemove(seating[0]);
    try stdout.print("{}\n", .{try optimizeHappiness(bp.arena, relatives, seating, &unseated)});
    try stdout.flush();
}

fn addName(allocator: std.mem.Allocator, names: *NameSet, name: []const u8) ![]const u8 {
    if (names.getKey(name)) |relative| {
        return relative;
    } else {
        const relative = try allocator.alloc(u8, name.len);
        @memcpy(relative, name);
        try names.put(allocator, relative, {});
        return relative;
    }
}

fn addOpinion(
    allocator: std.mem.Allocator,
    relatives: *RelativeTable,
    rel1: []const u8,
    rel2: []const u8,
    modifier: []const u8,
    points: i16,
) !void {
    const score = if (std.mem.eql(u8, modifier, "gain")) points else -points;
    var entry = try relatives.getOrPutValue(allocator, rel1, .empty);
    try entry.value_ptr.put(allocator, rel2, score);
}

fn optimizeHappiness(
    allocator: std.mem.Allocator,
    relatives: RelativeTable,
    seating: [][]const u8,
    unseated: *NameSet,
) !i16 {
    if (unseated.count() == 0) {
        var happiness: i16 = 0;
        for (seating, 0..) |rel1, i| {
            const happiness_table = relatives.get(rel1).?;
            happiness += happiness_table.get(seating[(i + seating.len - 1) % seating.len]).?;
            happiness += happiness_table.get(seating[(i + 1) % seating.len]).?;
        }
        return happiness;
    }

    const order = try allocator.alloc([]const u8, unseated.count());
    defer allocator.free(order);
    @memcpy(order, unseated.keys());

    var happiness: i16 = std.math.minInt(i16);
    for (order) |next| {
        seating[seating.len - unseated.count()] = next;
        _ = unseated.swapRemove(next);
        happiness = @max(happiness, try optimizeHappiness(allocator, relatives, seating, unseated));
        try unseated.put(allocator, next, {});
    }
    return happiness;
}
