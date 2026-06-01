const std = @import("std");
const Allocator = std.mem.Allocator;

const solver = @import("../solver.zig");
const WordIterator = @import("../parse.zig").WordIterator;

const Source = union(enum) {
    input: u16,
    bot: u16,
};
const Bot = struct {
    id: u16,
    source_a: ?Source = null,
    source_b: ?Source = null,
    value_low: ?u16 = null,
    value_high: ?u16 = null,
    output_low: ?u16 = null,
    output_high: ?u16 = null,
};
const Inputs = std.AutoHashMapUnmanaged(u16, u16);
const Bots = std.AutoHashMapUnmanaged(u16, Bot);

fn solveInt(gpa: Allocator, input: *std.Io.Reader) solver.Error!struct { ?u32, ?u32 } {
    var inputs: Inputs = .empty;
    var bots: Bots = .empty;
    defer inputs.deinit(gpa);
    defer bots.deinit(gpa);
    while (try input.takeDelimiter('\n')) |instruction| {
        try parseInstruction(gpa, &inputs, &bots, instruction);
    }
    return .{ try findIntersection(inputs, &bots, 61, 17), null };
}

fn parseInstruction(
    gpa: Allocator,
    inputs: *Inputs,
    bots: *Bots,
    instruction: []const u8,
) solver.Error!void {
    var it: WordIterator = .init(instruction);
    const kind = it.next() orelse return error.InvalidInput;
    if (std.mem.eql(u8, kind, "value")) {
        const value = try parseInt(it.next().?);
        for (0..3) |_| _ = it.next();
        const bot_id = try parseInt(it.next().?);
        try addSource(gpa, inputs, bots, bot_id, .{ .input = value });
    } else if (std.mem.eql(u8, kind, "bot")) {
        const bot_id = try parseInt(it.next().?);
        for (0..3) |_| _ = it.next();
        const low = try parseOutput(it.next().?, it.next().?);
        for (0..3) |_| _ = it.next();
        const high = try parseOutput(it.next().?, it.next().?);

        const result = try bots.getOrPut(gpa, bot_id);
        const bot_ptr = result.value_ptr;
        if (!result.found_existing) {
            bot_ptr.* = .{ .id = bot_id };
        }
        bot_ptr.output_low = low;
        bot_ptr.output_high = high;
        if (low) |dest_bot_id| {
            try addSource(gpa, inputs, bots, dest_bot_id, .{ .bot = bot_id });
        }
        if (high) |dest_bot_id| {
            try addSource(gpa, inputs, bots, dest_bot_id, .{ .bot = bot_id });
        }
    } else {
        return error.InvalidInput;
    }
}

fn addSource(gpa: Allocator, inputs: *Inputs, bots: *Bots, bot_id: u16, source: Source) error{OutOfMemory}!void {
    const result = try bots.getOrPut(gpa, bot_id);
    const bot_ptr = result.value_ptr;
    if (!result.found_existing) {
        bot_ptr.* = .{ .id = bot_id };
    }
    if (bot_ptr.source_b) |_| {
        unreachable;
    } else if (bot_ptr.source_a) |_| {
        bot_ptr.source_b = source;
    } else {
        bot_ptr.source_a = source;
    }
    switch (source) {
        .input => |value| try inputs.putNoClobber(gpa, value, bot_id),
        else => {},
    }
}

fn parseOutput(kind: []const u8, id: []const u8) error{InvalidInput}!?u16 {
    if (std.mem.eql(u8, kind, "bot")) {
        return try parseInt(id);
    } else {
        return null;
    }
}

fn parseInt(str: []const u8) error{InvalidInput}!u16 {
    return std.fmt.parseUnsigned(u16, str, 10) catch return error.InvalidInput;
}

fn findIntersection(inputs: Inputs, bots: *Bots, value_high: u16, value_low: u16) solver.Error!u16 {
    var bot = bots.getPtr(inputs.get(value_high).?).?;
    try computeValues(bots, bot);
    var i: usize = 0;
    while (bot.value_high.? != value_high or bot.value_low.? != value_low) : (i += 1) {
        if (value_high == bot.value_high) {
            bot = bots.getPtr(bot.output_high.?).?;
        } else if (value_high == bot.value_low) {
            bot = bots.getPtr(bot.output_low.?).?;
        }
        try computeValues(bots, bot);
    }
    return bot.id;
}

fn computeValues(bots: *Bots, bot: *Bot) solver.Error!void {
    if (bot.value_high) |_| return;
    const value_a = try computeValue(bots, bot.source_a.?, bot.id);
    const value_b = try computeValue(bots, bot.source_b.?, bot.id);
    bot.value_high = @max(value_a, value_b);
    bot.value_low = @min(value_a, value_b);
}

fn computeValue(bots: *Bots, source: Source, bot_id: u16) solver.Error!u16 {
    switch (source) {
        .input => |value| return value,
        .bot => |src_bot_id| {
            const src_bot = bots.getPtr(src_bot_id).?;
            try computeValues(bots, src_bot);
            if (src_bot.output_high.? == bot_id) {
                return src_bot.value_high.?;
            } else {
                return src_bot.value_low.?;
            }
        },
    }
}

pub const solve = solver.intSolver(u32, solveInt);
