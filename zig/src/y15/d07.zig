const std = @import("std");
const lib = @import("lib");

const Parser = lib.Parser;
const solver = lib.solver;

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

    fn init(alloc: std.mem.Allocator, gates: []const Gate) Self {
        var circuit: Self = .{ .inputs = .empty, .gates = .empty, .wires = .empty };
        for (gates) |gate| {
            circuit.addGate(alloc, gate);
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

    fn addGate(self: *Self, alloc: std.mem.Allocator, gate: Gate) void {
        switch (gate.inputs) {
            .AND, .OR => |in| {
                self.connectWire(alloc, in[0], gate);
                self.connectWire(alloc, in[1], gate);
            },
            .NOT => |in| {
                self.connectWire(alloc, in, gate);
            },
            .LSHIFT, .RSHIFT => |in| {
                self.connectWire(alloc, in[0], gate);
            },
            .SIGNAL => |in| {
                switch (in) {
                    .wire_id => self.connectWire(alloc, in, gate),
                    .signal => self.inputs.append(alloc, gate) catch unreachable,
                }
            },
        }
        self.wires.putNoClobber(alloc, gate.output, null) catch unreachable;
    }

    fn connectWire(self: *Self, alloc: std.mem.Allocator, input: Input, gate: Gate) void {
        switch (input) {
            .wire_id => |wire_id| {
                var entry = self.gates.getOrPutValue(alloc, wire_id, .empty) catch unreachable;
                entry.value_ptr.append(alloc, gate) catch unreachable;
            },
            .signal => {},
        }
    }

    fn resolve(self: *Self, alloc: std.mem.Allocator) void {
        var next: std.Deque(Gate) = .empty;
        defer next.deinit(alloc);

        // This handles any predefined signals. If the output wire has not been set, do so. Either
        // way, the gates connected to the output wire must be added to the queue. The reason for
        // this is that the simplest way to handle part 2 is to set the signal of a wire before the
        // resolution step.
        for (self.inputs.items) |gate| {
            if (self.getWireSignal(gate.output)) |_| {} else {
                const signal = self.resolveGate(gate).?;
                self.setWire(gate.output, signal);
            }
            if (self.gates.get(gate.output)) |connections| {
                for (connections.items) |g| {
                    next.pushBack(alloc, g) catch unreachable;
                }
            }
        }

        while (next.popFront()) |gate| {
            if (self.getWireSignal(gate.output)) |_| {
                continue;
            }
            if (self.resolveGate(gate)) |signal| {
                self.setWire(gate.output, signal);
                if (self.gates.get(gate.output)) |connections| {
                    for (connections.items) |g| {
                        next.pushBack(alloc, g) catch unreachable;
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

    fn setWire(self: *Self, wire_id: WireId, signal: Signal) void {
        const wire = self.wires.getPtr(wire_id).?;
        wire.* = signal;
    }

    fn getSignal(self: Self, input: Input) ?Signal {
        return switch (input) {
            .signal => |signal| signal,
            .wire_id => |wire_id| self.wires.get(wire_id) orelse unreachable,
        };
    }

    fn getWireSignal(self: Self, wire_id: WireId) ?Signal {
        return self.wires.get(wire_id) orelse unreachable;
    }
};

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u16, ?u16 } {
    var gates: std.ArrayList(Gate) = .empty;
    defer gates.deinit(tools.gpa);
    var reader = input.reader();
    while (try reader.takeDelimiter('\n')) |line| {
        gates.append(tools.gpa, try parseGate(line)) catch unreachable;
    }
    var circuit1: Circuit = .init(tools.gpa, gates.items);
    defer circuit1.deinit(tools.gpa);
    circuit1.resolve(tools.gpa);
    const answer1 = circuit1.getWireSignal('a') orelse return .{ null, null };

    var circuit2: Circuit = .init(tools.gpa, gates.items);
    defer circuit2.deinit(tools.gpa);
    circuit2.setWire('b', answer1);
    circuit2.resolve(tools.gpa);
    const answer2 = circuit2.getWireSignal('a');
    return .{ answer1, answer2 };
}

pub const solve = solver.intSolver(u16, solveInt);

fn parseGate(string: []const u8) solver.Error!Gate {
    var parser: Parser = .init(string, .{});
    const first = try parser.take();
    if (std.mem.eql(u8, first, "NOT")) {
        const input = try parseInput(try parser.take());
        try parser.skip();
        return .{
            .inputs = .{ .NOT = input },
            .output = try parseWire(try parser.take()),
        };
    }

    const input1 = try parseInput(first);
    if (parser.takeToken("->")) |_| {
        return .{
            .inputs = .{ .SIGNAL = input1 },
            .output = try parseWire(try parser.take()),
        };
    } else |_| {}

    const gate_type = try parser.takeEnum(GateType);
    const inputs: Inputs = switch (gate_type) {
        .AND => .{ .AND = .{ input1, try parseInput(try parser.take()) } },
        .OR => .{ .OR = .{ input1, try parseInput(try parser.take()) } },
        .LSHIFT => .{ .LSHIFT = .{ input1, try parser.takeInt(u4) } },
        .RSHIFT => .{ .RSHIFT = .{ input1, try parser.takeInt(u4) } },
        else => return error.InvalidToken,
    };
    try parser.skip();
    return .{ .inputs = inputs, .output = try parseWire(try parser.take()) };
}

fn parseInput(string: []const u8) solver.Error!Input {
    if (string[0] >= '0' and string[0] <= '9') {
        return .{ .signal = std.fmt.parseInt(u16, string, 10) catch return error.InvalidToken };
    } else {
        return .{ .wire_id = try parseWire(string) };
    }
}

fn parseWire(string: []const u8) solver.Error!WireId {
    if (string.len == 1) {
        return string[0];
    } else if (string.len == 2) {
        return (@as(WireId, string[0]) << 8) + string[1];
    } else {
        return error.InvalidInput;
    }
}
