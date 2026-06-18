const std = @import("std");

const solver = @import("../solver.zig");
const testing = @import("../testing.zig");

const Parser = @import("../Parser.zig");

const Time = struct {
    month: u8,
    day: u8,
    hour: u8,
    minute: u8,

    fn lessThan(self: Time, other: Time) bool {
        if (self.month < other.month) return true;
        if (other.month < self.month) return false;
        if (self.day < other.day) return true;
        if (other.day < self.day) return false;
        if (self.hour < other.hour) return true;
        if (other.hour < self.hour) return false;
        if (self.minute < other.minute) return true;
        return false;
    }
};

const Message = union(enum) {
    start: u16,
    wake: void,
    sleep: void,
};

const Event = struct {
    msg: Message,
    time: Time,
};

const SleepCounter = std.AutoHashMapUnmanaged(u16, [60]u8);

fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    const gpa = tools.gpa;
    var event_list: std.ArrayList(Event) = .empty;
    defer event_list.deinit(gpa);
    var sleep_counter: SleepCounter = .empty;
    defer sleep_counter.deinit(gpa);

    var lines = input.lines();
    while (lines.next()) |line| {
        const event = try parseEvent(line);
        try event_list.append(gpa, event);
        switch (event.msg) {
            .start => |guard_id| {
                const result = try sleep_counter.getOrPut(gpa, guard_id);
                if (!result.found_existing) {
                    @memset(result.value_ptr, 0);
                }
            },
            else => {},
        }
    }

    std.sort.pdq(Event, event_list.items, {}, cmpEvent);
    var guard_id: u16 = undefined;
    var sleep_start: u8 = undefined;
    for (event_list.items) |event| {
        switch (event.msg) {
            .start => |id| guard_id = id,
            .sleep => sleep_start = event.time.minute,
            .wake => {
                const times = sleep_counter.getPtr(guard_id).?;
                for (sleep_start..event.time.minute) |minute| {
                    times[minute] += 1;
                }
                sleep_start = undefined;
            },
        }
    }

    var max_sleep: u32 = 0;
    var guard: u16 = undefined;
    var it = sleep_counter.iterator();
    while (it.next()) |entry| {
        var sum: u32 = 0;
        for (entry.value_ptr.*) |score| sum += score;
        if (sum > max_sleep) {
            max_sleep = sum;
            guard = entry.key_ptr.*;
        }
    }

    const minute: u32 = @intCast(std.mem.findMax(u8, sleep_counter.getPtr(guard).?));
    return .{ minute * guard, null };
}

pub const solve = solver.intSolver(u32, solveInt);

test "solve" {
    const input =
        \\[1518-11-01 00:00] Guard #10 begins shift
        \\[1518-11-01 00:05] falls asleep
        \\[1518-11-01 00:25] wakes up
        \\[1518-11-01 00:30] falls asleep
        \\[1518-11-01 00:55] wakes up
        \\[1518-11-01 23:58] Guard #99 begins shift
        \\[1518-11-02 00:40] falls asleep
        \\[1518-11-02 00:50] wakes up
        \\[1518-11-03 00:05] Guard #10 begins shift
        \\[1518-11-03 00:24] falls asleep
        \\[1518-11-03 00:29] wakes up
        \\[1518-11-04 00:02] Guard #99 begins shift
        \\[1518-11-04 00:36] falls asleep
        \\[1518-11-04 00:46] wakes up
        \\[1518-11-05 00:03] Guard #99 begins shift
        \\[1518-11-05 00:45] falls asleep
        \\[1518-11-05 00:55] wakes up
    ;
    try testing.expectIntSolution(u32, solveInt, .{ 240, null }, input);
}

fn parseEvent(str: []const u8) Parser.Error!Event {
    var parser: Parser = .init(str[6..], .{});
    const time: Time = .{
        .month = try parser.findInt(u8),
        .day = try parser.findInt(u8),
        .hour = try parser.findInt(u8),
        .minute = try parser.findInt(u8),
    };
    try parser.skip();
    const next = try parser.take();
    const msg: Message = if (std.mem.eql(u8, next, "Guard"))
        .{ .start = try parser.findInt(u16) }
    else if (std.mem.eql(u8, next, "falls"))
        .{ .sleep = {} }
    else if (std.mem.eql(u8, next, "wakes"))
        .{ .wake = {} }
    else
        return error.InvalidToken;
    return .{ .msg = msg, .time = time };
}

fn cmpEvent(_: void, a: Event, b: Event) bool {
    return a.time.lessThan(b.time);
}
