const std = @import("std");

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

const NameTable = std.StringHashMapUnmanaged(usize);
const Program = struct {
    name: []const u8,
    weight: u16,
    parent: ?usize,
    children: []usize,

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

    const root = for (program_list.items) |program| {
        if (program.parent) |_| {} else break program;
    } else return .{ null, null };

    @memcpy(tools.p1buf[0..root.name.len], root.name);
    return .{ tools.p1buf[0..root.name.len], null };
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
        const program: Program = .{ .name = allocated, .weight = weight, .children = undefined, .parent = null };
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
        const program: Program = .{ .name = allocated, .weight = undefined, .children = undefined, .parent = null };
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
