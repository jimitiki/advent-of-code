const std = @import("std");
const Allocator = std.mem.Allocator;

const solver = @import("../solver.zig");
const Parser = @import("../Parser.zig");

const SourceType = enum { value, bot };
const DestinationType = enum { output, bot };
const Source = union(SourceType) {
    value: u16,
    bot: u16,
};
const Destination = union(DestinationType) {
    output: u16,
    bot: u16,
};
const Bot = struct {
    id: u16,
    source_a: ?Source = null,
    source_b: ?Source = null,
    value_low: ?u16 = null,
    value_high: ?u16 = null,
    dest_low: ?Destination = null,
    dest_high: ?Destination = null,
};
const Inputs = std.AutoHashMapUnmanaged(u16, u16);
const Outputs = std.AutoHashMapUnmanaged(u16, u16);
const Bots = std.AutoHashMapUnmanaged(u16, Bot);

fn solveInt(tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    var inputs: Inputs = .empty;
    defer inputs.deinit(tools.gpa);
    var outputs: Outputs = .empty;
    defer outputs.deinit(tools.gpa);
    var bots: Bots = .empty;
    defer bots.deinit(tools.gpa);

    while (try tools.input.reader.takeDelimiter('\n')) |instruction| {
        try parseInstruction(tools.gpa, &inputs, &outputs, &bots, instruction);
    }
    return .{
        try findIntersection(inputs, &bots, 61, 17),
        try computeOutput(&bots, outputs, 0) * try computeOutput(&bots, outputs, 1) * try computeOutput(&bots, outputs, 2),
    };
}

fn parseInstruction(
    gpa: Allocator,
    inputs: *Inputs,
    outputs: *Outputs,
    bots: *Bots,
    instruction: []const u8,
) solver.Error!void {
    var parser: Parser = .init(instruction, .{});
    switch (try parser.takeEnum(SourceType)) {
        .value => {
            const value = try parser.takeInt(u16);
            try parser.skipMany(3);
            const bot_id = try parser.takeInt(u16);
            try addSource(gpa, bots, bot_id, .{ .value = value });
            try inputs.putNoClobber(gpa, value, bot_id);
        },
        .bot => {
            const bot_id = try parser.takeInt(u16);
            try parser.skipMany(3);
            const low = try parseOutput(&parser);
            try parser.skipMany(3);
            const high = try parseOutput(&parser);
            try addBot(gpa, outputs, bots, bot_id, low, high);
        },
    }
}

fn addBot(
    gpa: Allocator,
    outputs: *Outputs,
    bots: *Bots,
    bot_id: u16,
    dest_low: Destination,
    dest_high: Destination,
) solver.Error!void {
    const result = try bots.getOrPut(gpa, bot_id);
    const bot_ptr = result.value_ptr;
    if (!result.found_existing) {
        bot_ptr.* = .{ .id = bot_id };
    }
    bot_ptr.dest_low = dest_low;
    bot_ptr.dest_high = dest_high;
    try addDestination(gpa, outputs, bots, bot_id, dest_low);
    try addDestination(gpa, outputs, bots, bot_id, dest_high);
}

fn addSource(gpa: Allocator, bots: *Bots, dest_bot_id: u16, source: Source) error{OutOfMemory}!void {
    const result = try bots.getOrPut(gpa, dest_bot_id);
    const bot_ptr = result.value_ptr;
    if (!result.found_existing) {
        bot_ptr.* = .{ .id = dest_bot_id };
    }
    if (bot_ptr.source_b) |_| {
        unreachable;
    } else if (bot_ptr.source_a) |_| {
        bot_ptr.source_b = source;
    } else {
        bot_ptr.source_a = source;
    }
}

fn addDestination(gpa: Allocator, outputs: *Outputs, bots: *Bots, bot_id: u16, destination: Destination) error{OutOfMemory}!void {
    switch (destination) {
        .output => |output| try outputs.putNoClobber(gpa, output, bot_id),
        .bot => |dest_bot_id| try addSource(gpa, bots, dest_bot_id, .{ .bot = bot_id }),
    }
}

fn parseOutput(parser: *Parser) Parser.Error!Destination {
    return switch (try parser.takeEnum(DestinationType)) {
        .bot => .{ .bot = try parser.takeInt(u16) },
        .output => .{ .output = try parser.takeInt(u16) },
    };
}

fn parseInt(str: []const u8) error{InvalidInput}!u16 {
    return std.fmt.parseUnsigned(u16, str, 10) catch return error.InvalidInput;
}

fn findIntersection(inputs: Inputs, bots: *Bots, value_high: u16, value_low: u16) solver.Error!u16 {
    var bot = bots.getPtr(inputs.get(value_high).?).?;
    try computeBotValues(bots, bot);
    var i: usize = 0;
    while (bot.value_high.? != value_high or bot.value_low.? != value_low) : (i += 1) {
        if (value_high == bot.value_high) {
            bot = bots.getPtr(bot.dest_high.?.bot).?;
        } else if (value_high == bot.value_low) {
            bot = bots.getPtr(bot.dest_low.?.bot).?;
        }
        try computeBotValues(bots, bot);
    }
    return bot.id;
}

fn computeBotValues(bots: *Bots, bot: *Bot) solver.Error!void {
    if (bot.value_high) |_| return;
    const value_a = try computeBotValue(bots, bot.source_a.?, bot.id);
    const value_b = try computeBotValue(bots, bot.source_b.?, bot.id);
    bot.value_high = @max(value_a, value_b);
    bot.value_low = @min(value_a, value_b);
}

fn computeBotValue(bots: *Bots, source: Source, bot_id: u16) solver.Error!u16 {
    switch (source) {
        .value => |value| return value,
        .bot => |src_bot_id| {
            const src_bot = bots.getPtr(src_bot_id).?;
            try computeBotValues(bots, src_bot);
            if (src_bot.dest_high.?.bot == bot_id) {
                return src_bot.value_high.?;
            } else {
                return src_bot.value_low.?;
            }
        },
    }
}

fn computeOutput(bots: *Bots, outputs: Outputs, output: u16) solver.Error!u16 {
    var bot = bots.get(outputs.get(output).?).?;
    try computeBotValues(bots, &bot);
    switch (bot.dest_high.?) {
        .output => return bot.value_high.?,
        else => switch (bot.dest_low.?) {
            .output => return bot.value_low.?,
            else => unreachable,
        },
    }
}

pub const solve = solver.intSolver(u32, solveInt);
