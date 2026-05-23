const std = @import("std");

const lib = @import("lib");
const Boilerplate = lib.Boilerplate;
const WordIterator = lib.parse.WordIterator;

const Sue = std.StringArrayHashMapUnmanaged(u8);

const sue_str = "Sue 0: children: 3, cats: 7, samoyeds: 2, pomeranians: 3, akitas: 0, vizslas: 0, goldfish: 5, trees: 3, cars: 2, perfumes: 1";

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;

    var sue = try parseSue(bp.arena, sue_str);
    defer sue.deinit(bp.arena);
    var i: usize = 1;
    const answer = while (try input.takeDelimiter('\n')) |line| : (i += 1) {
        var candidate = try parseSue(bp.arena, line);
        defer candidate.deinit(bp.arena);
        if (isMatch(sue, candidate, bp.part)) {
            break i;
        }
    } else return error.Unsolvable;

    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn parseSue(allocator: std.mem.Allocator, string: []const u8) !Sue {
    var it: WordIterator = .{ .string = string, .omit_punctuation = true };
    for (0..2) |_| _ = it.next();
    var sue: Sue = .empty;
    errdefer sue.deinit(allocator);
    while (try parseProperty(&it)) |property| {
        try sue.put(allocator, property[0], property[1]);
    }
    return sue;
}

fn parseProperty(it: *WordIterator) !?struct { []const u8, u8 } {
    if (it.next()) |name| {
        const value = try std.fmt.parseUnsigned(u8, it.next().?, 10);
        return .{ name[0 .. name.len - 1], value };
    } else {
        return null;
    }
}

fn isMatch(lhs: Sue, rhs: Sue, part: lib.Part) bool {
    var it = lhs.iterator();
    while (it.next()) |entry| {
        if (rhs.get(entry.key_ptr.*)) |expected| {
            if (part == .p2 and (std.mem.eql(u8, "cats", entry.key_ptr.*) or std.mem.eql(u8, "trees", entry.key_ptr.*))) {
                if (entry.value_ptr.* >= expected) {
                    return false;
                }
            } else if (part == .p2 and (std.mem.eql(u8, "pomeranians", entry.key_ptr.*) or std.mem.eql(u8, "goldfish", entry.key_ptr.*))) {
                if (entry.value_ptr.* <= expected) {
                    return false;
                }
            } else {
                if (expected != entry.value_ptr.*) {
                    return false;
                }
            }
        }
    }
    return true;
}
