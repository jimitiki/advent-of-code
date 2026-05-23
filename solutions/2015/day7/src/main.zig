const std = @import("std");

const lib = @import("lib");
const Boilerplate = lib.Boilerplate;
const splitWords = lib.parse.splitWords;

// TODO: Evaluate signal with "lazy recursion". Check the wires needed, if they haven't been evaluated yet, evaluate them, etc.

const WireId = u16;
const Signal = u16;
const Wire = ?Signal;
const WireMap = std.AutoHashMapUnmanaged(WireId, Wire);
const Input = union(enum) {
    wire_id: WireId,
    signal: Signal,
};
const GateType = enum { AND, OR, NOT, LSHIFT, RSHIFT, SIGNAL };
const Inputs = union(GateType) {
    AND: struct { Input, Input },
    OR: struct { Input, Input },
    NOT: Input,
    LSHIFT: struct { Input, u4 },
    RSHIFT: struct { Input, u4 },
    SIGNAL: Input,
};
const Gate = struct {
    const Self = @This();

    inputs: Inputs,
    output: WireId,
};
const Circuit = struct {
    const Self = @This();

    inputs: std.ArrayList(Gate),
    gates: std.AutoHashMapUnmanaged(u16, std.ArrayList(Gate)),
    wires: WireMap,

    fn init(alloc: std.mem.Allocator, gates: []Gate) !Self {
        var circuit: Self = .{ .inputs = .empty, .gates = .empty, .wires = .empty };
        for (gates) |gate| {
            try circuit.addGate(alloc, gate);
        }
        return circuit;
    }

    fn deinit(self: *Self, alloc: std.mem.Allocator) void {
        self.inputs.deinit(alloc);
        self.wires.deinit(alloc);
        var it = self.gates.valueIterator();
        while (it.next()) |gates| {
            gates.deinit(alloc);
        }
        self.gates.deinit(alloc);
    }

    fn addGate(self: *Self, alloc: std.mem.Allocator, gate: Gate) !void {
        switch (gate.inputs) {
            .AND, .OR => |in| {
                try self.connectWire(alloc, in[0], gate);
                try self.connectWire(alloc, in[1], gate);
            },
            .NOT => |in| {
                try self.connectWire(alloc, in, gate);
            },
            .LSHIFT, .RSHIFT => |in| {
                try self.connectWire(alloc, in[0], gate);
            },
            .SIGNAL => |in| {
                switch (in) {
                    .wire_id => try self.connectWire(alloc, in, gate),
                    .signal => try self.inputs.append(alloc, gate),
                }
            },
        }
        try self.wires.putNoClobber(alloc, gate.output, null);
    }

    fn connectWire(self: *Self, alloc: std.mem.Allocator, input: Input, gate: Gate) !void {
        switch (input) {
            .wire_id => |wire_id| {
                var entry = try self.gates.getOrPutValue(alloc, wire_id, .empty);
                try entry.value_ptr.append(alloc, gate);
            },
            .signal => {},
        }
    }

    fn resolve(self: *Self, alloc: std.mem.Allocator) !void {
        var next: std.Deque(Gate) = .empty;
        defer next.deinit(alloc);
        for (self.inputs.items) |gate| {
            try next.pushBack(alloc, gate);
        }
        while (next.popFront()) |gate| {
            if (self.getWireSignal(gate.output)) |_| {
                continue;
            }
            if (self.resolveGate(gate)) |signal| {
                try self.setWire(gate.output, signal);
                if (self.gates.get(gate.output)) |connections| {
                    for (connections.items) |g| {
                        try next.pushBack(alloc, g);
                    }
                }
            }
        }
    }

    fn resolveGate(self: *Self, gate: Gate) ?Signal {
        return switch (gate.inputs) {
            .AND => |in| exec_and: {
                if (self.getSignal(in[0])) |s1| {
                    if (self.getSignal(in[1])) |s2| {
                        break :exec_and s1 & s2;
                    }
                }
                break :exec_and null;
            },
            .OR => |in| exec_or: {
                if (self.getSignal(in[0])) |s1| {
                    if (self.getSignal(in[1])) |s2| {
                        break :exec_or s1 | s2;
                    }
                }
                break :exec_or null;
            },
            .NOT => |in| if (self.getSignal(in)) |s| ~s else null,
            .LSHIFT => |in| if (self.getSignal(in[0])) |s| s << in[1] else null,
            .RSHIFT => |in| if (self.getSignal(in[0])) |s| s >> in[1] else null,
            .SIGNAL => |in| return self.getSignal(in),
        };
    }

    fn setWire(self: *Self, wire_id: WireId, signal: Signal) !void {
        if (self.wires.getPtr(wire_id)) |wire| {
            if (wire.*) |_| {
                return error.InvalidCircuit;
            } else {
                wire.* = signal;
            }
        } else {
            return error.InvalidCircuit;
        }
    }

    fn getSignal(self: Self, input: Input) ?Signal {
        return switch (input) {
            .signal => |signal| signal,
            .wire_id => |wire_id| if (self.wires.get(wire_id)) |wire| wire else unreachable,
        };
    }

    fn getWireSignal(self: Self, wire_id: WireId) ?Signal {
        if (self.wires.get(wire_id)) |wire| {
            return wire;
        } else unreachable;
    }
};

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [256]u8 = undefined;
    var read_buffer: [256]u8 = undefined;
    var bp = try Boilerplate.init(init, &stdout_buffer, &read_buffer);
    defer bp.deinit();

    var stdout = &bp.stdout_writer.interface;
    var input = &bp.input_reader.interface;

    var gates: std.ArrayList(Gate) = .empty;
    defer gates.deinit(bp.arena);
    while (try input.takeDelimiter('\n')) |line| {
        try gates.append(bp.arena, try parseGate(line));
    }
    var circuit: Circuit = try .init(bp.arena, gates.items);
    defer circuit.deinit(bp.arena);

    try circuit.resolve(bp.arena);

    try stdout.print("{?}\n", .{circuit.getWireSignal('a')});
    try stdout.flush();
}

fn parseGate(string: []const u8) !Gate {
    var buf: [5][]const u8 = undefined;
    const words: [][]const u8 = if (try splitWords(&buf, string)) |w| w else return error.InvalidInput;

    if (std.mem.eql(u8, words[0], "NOT")) {
        return .{
            .inputs = .{ .NOT = try parseInput(words[1]) },
            .output = try parseWire(words[3]),
        };
    } else if (std.mem.eql(u8, words[1], "->")) {
        return .{
            .inputs = .{ .SIGNAL = try parseInput(words[0]) },
            .output = try parseWire(words[2]),
        };
    } else if (std.meta.stringToEnum(GateType, words[1])) |gate_type| {
        const input1 = try parseInput(words[0]);
        const inputs: Inputs = switch (gate_type) {
            .AND => .{ .AND = .{ input1, try parseInput(words[2]) } },
            .OR => .{ .OR = .{ input1, try parseInput(words[2]) } },
            .LSHIFT => .{ .LSHIFT = .{ input1, try std.fmt.parseInt(u4, words[2], 10) } },
            .RSHIFT => .{ .RSHIFT = .{ input1, try std.fmt.parseInt(u4, words[2], 10) } },
            else => return error.InvalidInput,
        };
        return .{ .inputs = inputs, .output = try parseWire(words[4]) };
    } else {
        return error.InvalidInput;
    }
}

fn parseInput(string: []const u8) !Input {
    if (string[0] >= '0' and string[0] <= '9') {
        return .{ .signal = try std.fmt.parseInt(u16, string, 10) };
    } else {
        return .{ .wire_id = try parseWire(string) };
    }
}

fn parseWire(string: []const u8) !WireId {
    if (string.len == 1) {
        return string[0];
    } else if (string.len == 2) {
        return (@as(WireId, string[0]) << 8) + string[1];
    } else {
        return error.InvalidInput;
    }
}
