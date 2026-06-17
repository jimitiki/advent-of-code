const std = @import("std");

const solver = @import("../solver.zig");

const Component = struct { u8, u8 };
const ComponentSet = std.AutoHashMapUnmanaged(Component, void);
const ComponentTable = std.AutoHashMapUnmanaged(u8, std.ArrayList(Component));

// TODO: Optimize

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    const gpa = tools.gpa;
    var components: ComponentTable = .empty;
    defer {
        var it = components.valueIterator();
        while (it.next()) |l| l.deinit(gpa);
        components.deinit(gpa);
    }

    var component_count: u8 = 0;
    while (try tools.input.takeDelimiter('\n')) |line| : (component_count += 1) {
        for (line, 0..) |char, i| {
            if (char == '/') {
                const component: Component = .{
                    std.fmt.parseInt(u8, line[0..i], 10) catch return error.InvalidInput,
                    std.fmt.parseInt(u8, line[i + 1 ..], 10) catch return error.InvalidInput,
                };

                const entry_a = try components.getOrPutValue(gpa, component[0], .empty);
                try entry_a.value_ptr.append(gpa, component);
                if (component[0] != component[1]) {
                    const entry_b = try components.getOrPutValue(gpa, component[1], .empty);
                    try entry_b.value_ptr.append(gpa, component);
                }
                break;
            }
        }
    }

    var used: ComponentSet = .empty;
    defer used.deinit(gpa);
    try used.ensureTotalCapacity(gpa, component_count);

    const p1 = strongest(components, &used, 0, 0);
    _, const p2 = longest(components, &used, 0, 0);
    return .{ p1, p2 };
}

pub const solve = solver.intSolver(u16, solveInt);

fn strongest(
    components: ComponentTable,
    used: *ComponentSet,
    port: u8,
    strength: u16,
) u16 {
    const compatible = components.get(port) orelse return strength;

    var max = strength;
    for (compatible.items) |next| {
        if (used.contains(next)) continue;

        const next_port: u8 = if (next[0] == port) next[1] else next[0];
        used.putAssumeCapacity(next, {});
        defer _ = used.remove(next);
        max = @max(max, strongest(components, used, next_port, strength + next[0] + next[1]));
    }
    return max;
}

fn longest(
    components: ComponentTable,
    used: *ComponentSet,
    port: u8,
    strength: u16,
) struct { u16, u16 } {
    var max: struct { u16, u16 } = .{ @intCast(used.size), strength };
    const compatible = components.get(port) orelse return max;

    for (compatible.items) |next| {
        if (used.contains(next)) continue;

        const next_port: u8 = if (next[0] == port) next[1] else next[0];
        used.putAssumeCapacity(next, {});
        defer _ = used.remove(next);
        const len, const str = longest(components, used, next_port, strength + next[0] + next[1]);
        if (len > max[0] or len == max[0] and str > max[1]) {
            max = .{ len, str };
        }
    }
    return max;
}
