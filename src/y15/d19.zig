const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

const MoleculeSet = std.StringHashMapUnmanaged(void);
const RuleTable = std.StringHashMapUnmanaged(std.ArrayList([]const u8));

// TODO: Implement part 2 using CYK algorithm?

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

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var molecules: MoleculeSet = .empty;
    defer {
        var it = molecules.keyIterator();
        while (it.next()) |m| tools.gpa.free(m.*);
        molecules.deinit(tools.gpa);
    }
    var rules: RuleTable = .empty;
    defer {
        var it = rules.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit(tools.gpa);
        }
        rules.deinit(tools.gpa);
    }
    while (try tools.input.takeDelimiter('\n')) |line| {
        if (line.len == 0) break;
        const in, const out = try parseRule(line);
        addRule(tools.gpa, &rules, in, out);
    }

    const molecule = try tools.input.takeDelimiter('\n') orelse return error.InvalidInput;
    const answer1 = calibrate(tools.gpa, rules, molecule);

    var it: AtomIterator = .{ .string = molecule };
    var total: u32 = 0;
    var ar_count: u32 = 0;
    var rn_count: u32 = 0;
    var y_count: u32 = 0;
    while (it.next()) |atom| {
        total += 1;
        if (std.mem.eql(u8, atom, "Ar")) {
            ar_count += 1;
        } else if (std.mem.eql(u8, atom, "Rn")) {
            rn_count += 1;
        } else if (std.mem.eql(u8, atom, "Y")) {
            y_count += 1;
        }
    }

    return .{ answer1, total - (ar_count + rn_count) - y_count * 2 - 1 };
}

pub const solve = solver.intSolver(u32, solveInt);

fn parseRule(string: []const u8) Parser.Error!struct { []const u8, []const u8 } {
    var parser: Parser = .init(string, .{});
    const start = try parser.take();
    try parser.skipToken("=>");
    return .{ start, try parser.take() };
}

fn calibrate(allocator: std.mem.Allocator, rules: RuleTable, molecule: []const u8) u32 {
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
                const result = std.mem.concat(allocator, u8, &parts) catch unreachable;
                if (generated.contains(result)) {
                    allocator.free(result);
                } else {
                    generated.put(allocator, result, {}) catch unreachable;
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

fn addRule(allocator: std.mem.Allocator, rules: *RuleTable, in: []const u8, out: []const u8) void {
    var rule = rules.getOrPutValue(allocator, in, .empty) catch unreachable;
    rule.value_ptr.append(allocator, out) catch unreachable;
}
