const std = @import("std");

const solver = @import("../solver.zig");

const Component = struct { u8, u8 };
const ComponentSet = std.AutoHashMapUnmanaged(Component, void);

// TODO: Optimize

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    var component_list: std.ArrayList(struct { u8, u8 }) = .empty;
    defer component_list.deinit(tools.gpa);

    while (try tools.input.takeDelimiter('\n')) |line| {
        for (line, 0..) |char, i| {
            if (char == '/') {
                // std.debug.print("[{s}]/[{s}]\n", .{line[0..i]})
                try component_list.append(tools.gpa, .{
                    std.fmt.parseInt(u8, line[0..i], 10) catch return error.InvalidInput,
                    std.fmt.parseInt(u8, line[i + 1 ..], 10) catch return error.InvalidInput,
                });
            }
        }
    }
    var used: ComponentSet = .empty;
    defer used.deinit(tools.gpa);
    try used.ensureTotalCapacity(tools.gpa, @intCast(component_list.items.len));
    return .{
        strongest(component_list.items, &used, 0, 0),
        longest(component_list.items, &used, 0, 0)[1],
    };
}

pub const solve = solver.intSolver(u16, solveInt);

fn strongest(
    components: []const Component,
    used: *ComponentSet,
    port: u8,
    strength: u16,
) u16 {
    var max = strength;
    for (components) |component| {
        if (used.contains(component)) continue;

        const next_port: ?u8 = if (component[0] == port) component[1] else if (component[1] == port) component[0] else null;
        if (next_port) |p| {
            used.putAssumeCapacity(component, {});
            defer _ = used.remove(component);
            max = @max(max, strongest(components, used, p, strength + component[0] + component[1]));
        }
    }
    return max;
}

fn longest(
    components: []const Component,
    used: *ComponentSet,
    port: u8,
    strength: u16,
) struct { u16, u16 } {
    var max: struct { u16, u16 } = .{ @intCast(used.size), strength };
    for (components) |component| {
        if (used.contains(component)) continue;

        const next_port: ?u8 = if (component[0] == port) component[1] else if (component[1] == port) component[0] else null;
        if (next_port) |p| {
            used.putAssumeCapacity(component, {});
            defer _ = used.remove(component);
            const len, const str = longest(components, used, p, strength + component[0] + component[1]);
            if (len > max[0] or len == max[0] and str > max[1]) {
                max = .{ len, str };
            }
        }
    }
    return max;
}
