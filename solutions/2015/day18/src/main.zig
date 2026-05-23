const std = @import("std");

const lib = @import("lib");
const Boilerplate = lib.Boilerplate;

const Row = std.bit_set.ArrayBitSet(usize, 102);

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;

    var grid_init = [_]Row{.empty} ** 102;
    const grid_next = [_]Row{.empty} ** 102;
    var i: usize = 1;
    while (try input.takeDelimiter('\n')) |line| : (i += 1) {
        grid_init[i] = parseRow(line);
    }
    if (bp.part == .p2) {
        grid_init[1].set(1);
        grid_init[1].set(100);
        grid_init[100].set(1);
        grid_init[100].set(100);
    }

    var grids: [2][102]Row = .{ grid_init, grid_next };
    var cur: usize = 0;
    for (0..100) |_| {
        updateGrid(&grids[cur], &grids[(cur + 1) % 2], bp.part);
        cur = (cur + 1) % 2;
    }

    var answer: usize = 0;
    for (grids[cur]) |row| {
        answer += row.count();
    }
    try stdout.print("{}\n", .{answer});
    try stdout.flush();
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

fn updateGrid(cur: []const Row, next: []Row, part: lib.Part) void {
    for (cur[1 .. cur.len - 1], 1..cur.len - 1) |row, i| {
        for (1..row.capacity() - 1) |j| {
            if (part == .p2 and (i == 1 or i == 100) and (j == 1 or j == 100)) {
                next[i].set(j);
                continue;
            }
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
}
