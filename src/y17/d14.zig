const std = @import("std");

const solver = @import("../solver.zig");
const t = @import("../test.zig");
const KnotHasher = @import("KnotHasher.zig");

const BitSet = std.bit_set.ArrayBitSet(u8, 128);
const Cache = std.AutoHashMapUnmanaged(struct { u8, u8 }, void);

const Disk = struct {
    grid: [128]BitSet = .{BitSet.initEmpty()} ** 128,

    fn used(self: Disk, pos: struct { u8, u8 }) bool {
        const idx = (pos[0] / 8) * 8 + 7 - pos[0] % 8;
        return self.grid[pos[1]].isSet(idx);
    }
};

// TODO: Find a more efficient way to store/access specific squares in the grid. (The real bottleneck, however, is the hashing.)

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    const key = try input.reader.takeDelimiter('\n') orelse return error.InvalidInput;
    var message = try tools.gpa.alloc(u8, key.len + 4);
    defer tools.gpa.free(message);

    @memcpy(message[0..key.len], key);
    message[key.len] = '-';

    var count_used: u16 = 0;
    var disk: Disk = .{};
    for (&disk.grid, 0..128) |*row, i| {
        const suffix = std.fmt.bufPrint(message[key.len + 1 ..], "{}", .{i}) catch unreachable;
        var hasher: KnotHasher = .init();
        hasher.hash(message[0 .. key.len + 1 + suffix.len], &row.masks);
        count_used += @intCast(row.count());
    }

    var explored: Cache = .empty;
    defer explored.deinit(tools.gpa);

    try explored.ensureTotalCapacity(tools.gpa, count_used);
    var region_count: u16 = 0;
    for (0..128) |i| {
        const y: u8 = @intCast(i);
        for (0..128) |j| {
            if (exploreRegionIfNeeded(disk, &explored, .{ @intCast(j), y })) {
                region_count += 1;
            }
        }
    }
    return .{ count_used, region_count };
}

pub const solve = solver.intSolver(u16, solveInt);

test "solve" {
    try t.expectIntSolution(u16, solveInt, .{ 8108, 1242 }, "flqrgnkx");
}

fn exploreRegion(disk: Disk, explored: *Cache, pos: struct { u8, u8 }) void {
    // std.debug.print("({}, {})", .{ pos[0], pos[1] });
    if (pos[0] > 0) {
        _ = exploreRegionIfNeeded(disk, explored, .{ pos[0] - 1, pos[1] });
    }
    if (pos[0] < 127) {
        _ = exploreRegionIfNeeded(disk, explored, .{ pos[0] + 1, pos[1] });
    }
    if (pos[1] > 0) {
        _ = exploreRegionIfNeeded(disk, explored, .{ pos[0], pos[1] - 1 });
    }
    if (pos[1] < 127) {
        _ = exploreRegionIfNeeded(disk, explored, .{ pos[0], pos[1] + 1 });
    }
}

fn exploreRegionIfNeeded(disk: Disk, explored: *Cache, pos: struct { u8, u8 }) bool {
    if (!disk.used(pos)) return false;
    if (explored.getOrPutAssumeCapacity(pos).found_existing) return false;
    exploreRegion(disk, explored, pos);
    return true;
}
