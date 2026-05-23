const std = @import("std");

const lib = @import("lib");
const Boilerplate = lib.Boilerplate;
const WordIterator = lib.parse.WordIterator;

const MoleculeSet = std.StringHashMapUnmanaged(void);
const RuleTable = std.StringHashMapUnmanaged(std.ArrayList([]const u8));

// TODO: Implement part 2 programatically. Maybe using CYK algorithm?

const AtomIterator = struct {
    string: []const u8,
    index: usize = 0,

    const Self = @This();

    pub fn next(self: *Self) ?[]const u8 {
        if (self.index >= self.string.len) {
            return null;
        }
        var end = self.index + 1;
        while (end < self.string.len and self.string[end] >= 'a' and self.string[end] <= 'z') : (end += 1) {}
        const atom = self.string[self.index..end];
        self.index = end;
        return atom;
    }
};

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [1024]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    const answer = try computeP1(&bp);

    var stdout = &bp.stdout_writer.interface;
    try stdout.print("{}\n", .{answer});
    try stdout.flush();
}

fn computeP1(bp: *Boilerplate) !u32 {
    var input = &bp.input_reader.interface;
    var molecules: MoleculeSet = .empty;
    defer {
        var it = molecules.keyIterator();
        while (it.next()) |m| bp.arena.free(m.*);
        molecules.deinit(bp.arena);
    }
    var rules: RuleTable = .empty;
    defer rules.deinit(bp.arena);
    while (try input.takeDelimiter('\n')) |line| {
        if (line.len == 0) break;
        const in, const out = parseRule(line);
        try addRule(bp.arena, &rules, in, out);
    }

    const molecule = try input.takeDelimiter('\n') orelse return error.InvalidInput;
    return calibrate(bp.arena, rules, molecule);
}

fn parseRule(string: []const u8) struct { []const u8, []const u8 } {
    var it: WordIterator = .{ .string = string };
    const start = it.next().?;
    _ = it.next();
    return .{ start, it.next().? };
}

fn calibrate(allocator: std.mem.Allocator, rules: RuleTable, molecule: []const u8) !u32 {
    var generated: MoleculeSet = .empty;
    defer {
        var it = generated.keyIterator();
        while (it.next()) |m| allocator.free(m.*);
        generated.deinit(allocator);
    }

    var it: AtomIterator = .{ .string = molecule };
    while (it.next()) |atom| {
        if (rules.get(atom)) |outputs| {
            for (outputs.items) |output| {
                const parts = [_][]const u8{ molecule[0 .. it.index - atom.len], output, molecule[it.index..] };
                const result = try std.mem.concat(allocator, u8, &parts);
                if (generated.contains(result)) {
                    allocator.free(result);
                } else {
                    try generated.put(allocator, result, {});
                }
            }
        }
    }
    return generated.size;
}

fn addMolecule(allocator: std.mem.Allocator, molecules: *MoleculeSet, molecule: []const u8) ![]const u8 {
    if (molecules.get(molecule)) |m| {
        return m;
    } else {
        const m = allocator.alloc(u8, molecule.len);
        errdefer allocator.free(m);
        @memcpy(m, molecule);
        try molecules.put(allocator, m, {});
        return m;
    }
}

fn addRule(allocator: std.mem.Allocator, rules: *RuleTable, in: []const u8, out: []const u8) !void {
    var rule = try rules.getOrPutValue(allocator, in, .empty);
    try rule.value_ptr.append(allocator, out);
}
