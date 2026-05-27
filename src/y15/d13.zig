const std = @import("std");

const solver = @import("../solver.zig");
const WordIterator = @import("../parse.zig").WordIterator;

const NameSet = std.StringArrayHashMapUnmanaged(void);
const HappinessTable = std.StringHashMapUnmanaged(i16);
const RelativeTable = std.StringHashMapUnmanaged(HappinessTable);

// TODO: Use indeces to represent relatives - switch from hash maps to slices.

fn solveInt(gpa: std.mem.Allocator, input: *std.Io.Reader) solver.Error!struct { ?i16, ?i16 } {
    var names: NameSet = .empty;
    defer {
        for (names.keys()) |name| {
            gpa.free(name);
        }
        names.deinit(gpa);
    }
    var relatives: RelativeTable = .empty;
    defer {
        var it = relatives.valueIterator();
        while (it.next()) |value| {
            value.deinit(gpa);
        }
        relatives.deinit(gpa);
    }
    while (try input.takeDelimiter('\n')) |line| {
        var it = WordIterator.init(line[0 .. line.len - 1]);
        const name1 = it.next().?;
        _ = it.next().?;
        const mod = it.next().?;
        const points = std.fmt.parseInt(i16, it.next().?, 10) catch return error.InvalidInput;
        for (0..6) |_| _ = it.next().?;
        const name2 = it.next().?;

        const rel1 = addName(gpa, &names, name1);
        const rel2 = addName(gpa, &names, name2);
        addOpinion(gpa, &relatives, rel1, rel2, mod, points);
    }

    const seating = gpa.alloc([]const u8, names.count() + 1) catch unreachable;
    defer gpa.free(seating);
    seating[0] = names.keys()[0];
    var unseated: NameSet = names.clone(gpa) catch unreachable;
    defer unseated.deinit(gpa);
    _ = unseated.swapRemove(seating[0]);
    const answer1 = optimizeHappiness(gpa, relatives, seating[0 .. seating.len - 1], &unseated);

    var table: HappinessTable = .empty;
    const self = addName(gpa, &names, "");
    unseated.put(gpa, self, {}) catch unreachable;
    for (names.keys()) |name| {
        if (std.mem.eql(u8, name, self)) {
            continue;
        }
        table.put(gpa, name, 0) catch unreachable;
        relatives.getPtr(name).?.put(gpa, self, 0) catch unreachable;
    }
    relatives.put(gpa, self, table) catch unreachable;
    const answer2 = optimizeHappiness(gpa, relatives, seating, &unseated);

    return .{ answer1, answer2 };
}

pub const solve = solver.intSolver(i16, solveInt);

fn addName(allocator: std.mem.Allocator, names: *NameSet, name: []const u8) []const u8 {
    if (names.getKey(name)) |relative| {
        return relative;
    } else {
        const relative = allocator.alloc(u8, name.len) catch unreachable;
        @memcpy(relative, name);
        names.put(allocator, relative, {}) catch unreachable;
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
) void {
    const score = if (std.mem.eql(u8, modifier, "gain")) points else -points;
    var entry = relatives.getOrPutValue(allocator, rel1, .empty) catch unreachable;
    entry.value_ptr.put(allocator, rel2, score) catch unreachable;
}

fn optimizeHappiness(
    allocator: std.mem.Allocator,
    relatives: RelativeTable,
    seating: [][]const u8,
    unseated: *NameSet,
) i16 {
    if (unseated.count() == 0) {
        var happiness: i16 = 0;
        for (seating, 0..) |rel1, i| {
            const happiness_table = relatives.get(rel1).?;
            happiness += happiness_table.get(seating[(i + seating.len - 1) % seating.len]).?;
            happiness += happiness_table.get(seating[(i + 1) % seating.len]).?;
        }
        return happiness;
    }

    const order = allocator.alloc([]const u8, unseated.count()) catch unreachable;
    defer allocator.free(order);
    @memcpy(order, unseated.keys());

    var happiness: i16 = std.math.minInt(i16);
    for (order) |next| {
        seating[seating.len - unseated.count()] = next;
        _ = unseated.swapRemove(next);
        happiness = @max(happiness, optimizeHappiness(allocator, relatives, seating, unseated));
        unseated.put(allocator, next, {}) catch unreachable;
    }
    return happiness;
}
