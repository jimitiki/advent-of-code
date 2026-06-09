const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

const NameTable = std.StringHashMapUnmanaged(usize);
const Program = struct {
    name: []const u8,
    weight: u16,
    total_weight: u32,
    parent: ?usize,
    children: []usize,

    fn init(name: []const u8, weight: u16) Program {
        return .{ .name = name, .weight = weight, .total_weight = undefined, .parent = null, .children = undefined };
    }

    fn free(self: Program, gpa: std.mem.Allocator) void {
        gpa.free(self.name);
        gpa.free(self.children);
    }
};

pub fn solve(tools: solver.Tools) solver.Error!solver.Result {
    const gpa = tools.gpa;
    var program_list: std.ArrayList(Program) = .empty;
    defer {
        for (program_list.items) |node| node.free(gpa);
        program_list.deinit(gpa);
    }
    var name_lookup: NameTable = .empty;
    defer name_lookup.deinit(gpa);

    while (try tools.input.takeDelimiter('\n')) |line| {
        var parser: Parser = .init(line, .{});
        const name = try parser.take();
        const weight_str = try parser.take();
        const weight = std.fmt.parseUnsigned(u16, weight_str[1 .. weight_str.len - 1], 10) catch return error.InvalidInput;
        const id = try registerProgram(gpa, &program_list, &name_lookup, name, weight);
        const children = try parseChildren(gpa, &program_list, &name_lookup, &parser);
        for (children) |child_id| {
            program_list.items[child_id].parent = id;
        }
        program_list.items[id].children = children;
    }

    var root = program_list.items[0];
    while (root.parent) |p| : (root = program_list.items[p]) {}
    const p1 = tools.p1buf[0..root.name.len];
    @memcpy(p1, root.name);

    _ = computeTotalWeight(program_list.items, &root);
    const target_weight = computeNeededWeight(program_list.items, root);
    const p2 = if (target_weight) |w| std.fmt.bufPrint(tools.p2buf, "{}", .{w}) catch unreachable else null;

    return .{ p1, p2 };
}

fn registerProgram(
    gpa: std.mem.Allocator,
    program_list: *std.ArrayList(Program),
    name_lookup: *NameTable,
    name: []const u8,
    weight: u16,
) error{OutOfMemory}!usize {
    if (name_lookup.get(name)) |id| {
        program_list.items[id].weight = weight;
        return id;
    } else {
        const allocated = try gpa.alloc(u8, name.len);
        @memcpy(allocated, name);
        const program: Program = .init(allocated, weight);
        try name_lookup.put(gpa, allocated, program_list.items.len);
        try program_list.append(gpa, program);
        return program_list.items.len - 1;
    }
}

fn registerChild(
    gpa: std.mem.Allocator,
    program_list: *std.ArrayList(Program),
    name_lookup: *NameTable,
    name: []const u8,
) error{OutOfMemory}!usize {
    if (name_lookup.get(name)) |id| {
        return id;
    } else {
        const allocated = try gpa.alloc(u8, name.len);
        @memcpy(allocated, name);
        const program: Program = .init(allocated, undefined);
        try name_lookup.put(gpa, allocated, program_list.items.len);
        try program_list.append(gpa, program);
        return program_list.items.len - 1;
    }
}

fn parseChildren(
    gpa: std.mem.Allocator,
    program_list: *std.ArrayList(Program),
    name_lookup: *NameTable,
    parser: *Parser,
) error{OutOfMemory}![]usize {
    parser.skip() catch return &.{};
    var child_count: u8 = 1;
    for (parser.buf[parser.index..]) |char| {
        if (char == ',') child_count += 1;
    }
    const children = try gpa.alloc(usize, child_count);

    var idx: u8 = 0;
    while (idx < child_count) : (idx += 1) {
        const name = parser.take() catch break;
        const id = try registerChild(gpa, program_list, name_lookup, name);
        children[idx] = id;
    }
    return children;
}

fn computeTotalWeight(programs: []Program, root: *Program) u32 {
    var sum: u32 = root.weight;
    for (root.children) |child_id| {
        sum += computeTotalWeight(programs, &programs[child_id]);
    }
    root.total_weight = sum;
    return sum;
}

fn computeNeededWeight(programs: []const Program, root: Program) ?u32 {
    if (findImbalancedChild(programs, root.children)) |result| {
        const target, const child_id = result;
        if (computeNeededWeight(programs, programs[child_id])) |weight| {
            return weight;
        } else {
            return target;
        }
    }
    return null;
}

fn findImbalancedChild(programs: []const Program, children: []usize) ?struct { u32, usize } {
    if (children.len < 2) return null;

    const w1 = programs[children[0]].total_weight;
    const w2 = programs[children[1]].total_weight;
    if (w1 == w2) {
        if (children.len == 2) return null;
        for (children[2..]) |child_id| {
            const program = programs[child_id];
            if (program.total_weight != w1) {
                return .{ computeAdjustment(w1, program), child_id };
            }
        }
        return null;
    }
    const target = programs[children[2]].total_weight;
    if (w1 == target) {
        return .{ computeAdjustment(target, programs[children[1]]), children[1] };
    } else {
        return .{ computeAdjustment(target, programs[children[0]]), children[0] };
    }
}

fn computeAdjustment(target_weight: u32, program: Program) u32 {
    return target_weight - (program.total_weight - program.weight);
}
