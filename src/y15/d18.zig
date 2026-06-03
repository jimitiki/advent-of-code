const std = @import("std");

const solver = @import("../solver.zig");

const Row = std.bit_set.ArrayBitSet(usize, 102);

// TODO: Create a visualization

fn solveInt(tools: solver.Tools) solver.Error!struct { ?usize, ?usize } {
    var grid = [_]Row{.empty} ** 102;
    var i: usize = 1;
    while (try tools.input.takeDelimiter('\n')) |line| : (i += 1) {
        grid[i] = parseRow(line);
    }
    return .{ run(grid, false), run(grid, true) };
}

pub const solve = solver.intSolver(usize, solveInt);

fn run(grid_init: [102]Row, keep_corners_lit: bool) usize {
    var grid1 = [_]Row{.empty} ** 102;
    var grid2 = [_]Row{.empty} ** 102;
    copyGrid(&grid1, grid_init);
    const grids: [2]*[102]Row = .{ &grid1, &grid2 };

    if (keep_corners_lit) {
        grid1[1].set(1);
        grid1[1].set(100);
        grid1[100].set(1);
        grid1[100].set(100);
    }

    var cur: usize = 0;
    for (0..100) |_| {
        updateGrid(grids[cur], grids[(cur + 1) % 2], keep_corners_lit);
        cur = (cur + 1) % 2;
    }

    var light_count: usize = 0;
    for (grids[cur]) |row| {
        light_count += row.count();
    }
    return light_count;
}

fn parseRow(string: []const u8) Row {
    var row: Row = .empty;
    for (string, 1..) |c, i| {
        if (c == '#') {
            row.set(i);
        }
    }
    return row;
}

fn copyGrid(dest: *[102]Row, source: [102]Row) void {
    for (dest, source) |*dest_row, source_row| {
        dest_row.setRangeValue(.{ .start = 0, .end = dest_row.capacity() }, false);
        dest_row.setUnion(source_row);
    }
}

fn updateGrid(cur: []const Row, next: *[102]Row, keep_corners_lit: bool) void {
    for (cur[1 .. cur.len - 1], 1..cur.len - 1) |row, i| {
        for (1..row.capacity() - 1) |j| {
            var on_adj: u8 = 0;
            for (i - 1..i + 2) |k| {
                for (j - 1..j + 2) |l| {
                    if (k == i and l == j) continue;
                    if (cur[k].isSet(l)) on_adj += 1;
                }
            }
            if (row.isSet(j)) {
                next[i].setValue(j, on_adj == 2 or on_adj == 3);
            } else {
                next[i].setValue(j, on_adj == 3);
            }
        }
    }
    if (keep_corners_lit) {
        next[1].set(1);
        next[1].set(100);
        next[100].set(1);
        next[100].set(100);
    }
}
