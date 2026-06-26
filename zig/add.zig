const std = @import("std");

const last_year = 25;

const int_base =
    \\const std = @import("std");
    \\
    \\const solver = @import("../solver.zig");
    \\const testing = @import("../testing.zig");
    \\
    \\fn solveInt(input: solver.Input, tools: solver.Tools) solver.Error!struct { ?u32, ?u32 } {
    \\    _ = tools;
    \\
    \\    _ = try input.firstLine();
    \\
    \\    var parser = input.parser(.{});
    \\    _ = try parser.takeInt(u32);
    \\
    \\    var lines = input.lines();
    \\    while (lines.next()) |line| {
    \\        _ = line;
    \\    }
    \\
    \\    return .{ null, null };
    \\}
    \\
    \\pub const solve = solver.intSolver(u32, solveInt);
    \\
;

const str_base =
    \\const std = @import("std");
    \\
    \\const solver = @import("../solver.zig");
    \\const testing = @import("../testing.zig");
    \\
    \\pub fn solve(input: solver.Input, tools: solver.Tools, p1buf: *[32]u8, p2buf: *[32]u8) solver.Error!solver.Result {
    \\    _ = tools;
    \\    _ = p1buf;
    \\    _ = p2buf;
    \\
    \\    _ = try input.firstLine();
    \\
    \\    var parser = input.parser(.{});
    \\    _ = try parser.takeInt(u32);
    \\
    \\    var lines = input.lines();
    \\    while (lines.next()) |line| {
    \\        _ = line;
    \\    }
    \\
    \\    return .{ null, null };
    \\}
    \\
;

const BaseType = enum { i, s };

const YearIterator = struct {
    reader: *std.Io.Reader,
    index: usize = 0,

    const Self = @This();

    pub fn next(self: *Self) error{Malformed}!?u8 {
        _ = self.reader.discardDelimiterInclusive('\n') catch unreachable;
        while (true) {
            if (self.reader.peekDelimiterInclusive('\n')) |line| {
                if (extractYear(line)) |year| {
                    return year;
                } else if (std.mem.eql(u8, line, "};\n")) {
                    return null;
                }
                _ = self.reader.discard(.limited(line.len)) catch unreachable;
            } else |_| {
                return error.Malformed;
            }
        }
    }
};

const DayIterator = struct {
    reader: *std.Io.Reader,
    index: usize = 0,

    const Self = @This();

    pub fn next(self: *Self) error{Malformed}!?u8 {
        _ = self.reader.discardDelimiterInclusive('\n') catch unreachable;
        while (true) {
            if (self.reader.peekDelimiterInclusive('\n')) |line| {
                if (extractDay(line)) |day| {
                    return day;
                } else if (std.mem.eql(u8, line, "    },\n")) {
                    return null;
                } else if (std.mem.eql(u8, line, "    &.{},\n")) {
                    return null;
                }
                _ = self.reader.discard(.limited(line.len)) catch unreachable;
            } else |_| {
                return error.Malformed;
            }
        }
    }
};

pub fn main(init: std.process.Init) !void {
    const gpa = init.arena.allocator();
    const args = try init.minimal.args.toSlice(gpa);

    const base_type = std.meta.stringToEnum(BaseType, args[2]).?;
    const dir = try std.Io.Dir.openDirAbsolute(init.io, args[1], .{});
    const year_arg: ?u8 = if (args.len < 4) null else try std.fmt.parseInt(u8, args[3], 10);
    const day_arg: ?u8 = if (args.len < 5) null else try std.fmt.parseInt(u8, args[4], 10);
    if (year_arg) |year| {
        if (year < 15) {
            std.debug.print("{} is before the first year", .{@as(u16, year) + 2000});
            return;
        }
        if (year > last_year) {
            std.debug.print("{} is beyond the last known year", .{@as(u16, year) + 2000});
            return;
        }
        if (day_arg) |day| {
            if (year >= 25 and day > 12 or day > 25) {
                std.debug.print("{} is beyond the final date", .{day});
                return;
            }
            if (day < 1) {
                std.debug.print("{} is before the first date", .{day});
                return;
            }
        }
    }

    const text = try dir.readFileAlloc(init.io, "src/solutions.zig", gpa, .unlimited);
    var reader = std.Io.Reader.fixed(text);
    const year, const day, const exists = findOpenDayAndYear(year_arg, day_arg, &reader) catch |err| {
        switch (err) {
            error.AlreadyExists => std.debug.print("Solution already exists\n", .{}),
            error.Malformed => std.debug.print("Solutions file is malformed\n", .{}),
            error.YearFull => std.debug.print("No missing solutions for year\n", .{}),
        }
        return;
    };
    std.debug.print("Adding solution for 20{}.{}\n", .{ year, day });

    var buf: [1024]u8 = undefined;
    const input_dir_path = try std.fmt.bufPrint(&buf, "../inputs/y{}/", .{year});
    const input_dir = try dir.createDirPathOpen(init.io, input_dir_path, .{});
    const input_file_name = try std.fmt.bufPrint(&buf, "d{:0>2}.txt", .{day});
    if (input_dir.createFile(init.io, input_file_name, .{ .exclusive = true })) |f| {
        std.debug.print("Retrieving input... ", .{});
        defer f.close(init.io);
        const input = if (fetchInput(gpa, init.io, &buf, dir, year, day)) |input| input else |err| {
            std.debug.print("FAILED\n", .{});
            return err;
        };
        std.debug.print("Done\n", .{});
        try f.writePositionalAll(init.io, input, 0);
    } else |err| {
        switch (err) {
            error.PathAlreadyExists => {},
            else => |e| return e,
        }
    }

    const src_dir_path = try std.fmt.bufPrint(&buf, "src/y{}/", .{year});
    const src_dir = try dir.createDirPathOpen(init.io, src_dir_path, .{});
    const src_file_name = try std.fmt.bufPrint(&buf, "d{:0>2}.zig", .{day});
    const base = switch (base_type) {
        .i => int_base,
        .s => str_base,
    };
    src_dir.writeFile(init.io, .{ .data = base, .sub_path = src_file_name, .flags = .{ .exclusive = true } }) catch |err| {
        switch (err) {
            error.PathAlreadyExists => {},
            else => |e| return e,
        }
    };

    const test_text = try dir.readFileAlloc(init.io, "src/testing.zig", gpa, .unlimited);
    var test_reader = std.Io.Reader.fixed(test_text);
    while (try test_reader.takeDelimiter('\n')) |line| {
        if (line.len > 4 and std.mem.eql(u8, "test ", line[0..5])) break;
    }
    while (true) : (_ = try test_reader.discardDelimiterInclusive('\n')) {
        const line = try test_reader.peekDelimiterExclusive('\n');
        if (line.len == 1 and line[0] == '}') break;
        if (line.len < 24) continue;
        const y = std.fmt.parseUnsigned(u8, line[18..20], 10) catch continue;
        if (year < y) break;
        const d = std.fmt.parseUnsigned(u8, line[22..24], 10) catch continue;
        if (year == y and day < d) break;
    }
    const test_file = try dir.openFile(init.io, "src/testing.zig", .{ .mode = .write_only });
    defer test_file.close(init.io);

    var testw = test_file.writer(init.io, &buf);
    var test_writer = &testw.interface;
    try test_writer.writeAll(test_text[0..test_reader.seek]);
    try test_writer.print("    _ = @import(\"y{}/d{:0>2}.zig\");\n", .{ year, day });
    try test_writer.writeAll(test_text[test_reader.seek..test_text.len]);
    try test_writer.flush();

    const solutions_file = try dir.createFile(init.io, "src/solutions.zig", .{ .truncate = true });
    defer solutions_file.close(init.io);
    var file_writer = solutions_file.writer(init.io, &buf);
    var writer = &file_writer.interface;

    _ = try writer.writeAll(text[0..reader.seek]);
    const expand_year = std.mem.eql(u8, "    &.{},\n", try reader.peekDelimiterInclusive('\n'));
    if (expand_year) _ = try reader.discardDelimiterInclusive('\n');
    if (!exists or expand_year) {
        if (!exists) {
            try writer.print("    // 20{}\n", .{year});
        }
        _ = try writer.writeAll("    &.{\n");
    }
    try writer.print("        @import(\"y{}/d{:0>2}.zig\").solve,\n", .{ year, day });
    if (!exists or expand_year) {
        _ = try writer.writeAll("    },\n");
    }
    _ = try writer.writeAll(text[reader.seek..]);
    try writer.flush();

    std.debug.print("Done.\n", .{});
}

fn findOpenDayAndYear(year: ?u8, day: ?u8, reader: *std.Io.Reader) error{ AlreadyExists, YearFull, Malformed }!struct { u8, u8, bool } {
    if (day) |d| {
        const exists = try advanceToYear(year.?, reader);
        _ = try advanceToDay(d, reader);
        return .{ year.?, d, exists };
    }

    if (year) |y| {
        const exists = try advanceToYear(y, reader);
        if (!exists) {
            return .{ @intCast(y), 1, true };
        }
        const d = try findOpenDay(y, reader);
        return .{ y, d, true };
    }

    for (15..last_year) |y| {
        const yr: u8 = @intCast(y);
        const exists = advanceToYear(yr, reader) catch break;
        if (!exists) {
            return .{ yr, 1, true };
        }
        if (findOpenDay(yr, reader)) |d| {
            return .{ yr, d, true };
        } else |err| {
            switch (err) {
                error.YearFull => {},
                error.Malformed => return err,
            }
        }
    }
    return error.AlreadyExists;
}

fn fetchInput(allocator: std.mem.Allocator, io: std.Io, buf: []u8, dir: std.Io.Dir, year: u8, day: u8) ![]const u8 {
    var headers: [1]std.http.Header = undefined;
    const cookie = try dir.readFileAlloc(io, "../cookie.txt", allocator, .unlimited);
    headers[0] = .{ .name = "Cookie", .value = cookie };
    const url = try std.fmt.bufPrint(buf, "https://adventofcode.com/20{:0>2}/day/{}/input", .{ year, day });

    var client: std.http.Client = .{ .allocator = allocator, .io = io };
    var req = try client.request(.GET, try .parse(url), .{ .extra_headers = &headers });
    defer req.deinit();

    _ = try req.sendBodiless();
    var resp = try req.receiveHead(buf);

    var transfer_buf: [1024]u8 = undefined;
    var decompress_buf: [65536]u8 = undefined;
    var decompress: std.http.Decompress = undefined;
    var resp_reader = resp.readerDecompressing(&transfer_buf, &decompress, &decompress_buf);
    const input = try resp_reader.allocRemaining(allocator, .unlimited);
    return input;
}

fn findOpenDay(year: u8, reader: *std.Io.Reader) error{ YearFull, Malformed }!u8 {
    var day: u8 = 0;
    var it: DayIterator = .{ .reader = reader };
    while (try it.next()) |d| {
        if (d - day > 1) {
            return day + 1;
        }
        day = d;
    }
    if (day >= 25 or year >= 25 and day >= 12) {
        return error.YearFull;
    } else {
        return day + 1;
    }
}

/// Advances the reader's position to the first line that declares a solution in the provided year.
/// Returns `true` if the year already exists in the file, or `false` otherwise.
fn advanceToYear(year: u8, reader: *std.Io.Reader) error{Malformed}!bool {
    var it: YearIterator = .{ .reader = reader };
    while (try it.next()) |y| {
        if (y == year) {
            return true;
        }
    }
    return false;
}

/// Advances the reader's position to the line where the provided day's solution should go. Assumes
/// that the reader has been advanced to the correct year
fn advanceToDay(day: u8, reader: *std.Io.Reader) error{ AlreadyExists, Malformed }!void {
    var it: DayIterator = .{ .reader = reader };
    while (try it.next()) |d| {
        if (d == day) {
            return error.AlreadyExists;
        } else if (d > day) {
            return;
        }
    }
    return;
}

fn extractYear(line: []const u8) ?u8 {
    const prefix = "    // 20";
    if (!startsWith(prefix, line)) return null;
    return std.fmt.parseInt(u8, line[prefix.len .. prefix.len + 2], 10) catch null;
}

fn extractDay(line: []const u8) ?u8 {
    const prefix = "        @import(\"y";
    if (!startsWith(prefix, line)) return null;
    return std.fmt.parseInt(u8, line[prefix.len + 4 .. prefix.len + 6], 10) catch return null;
}

fn startsWith(prefix: []const u8, str: []const u8) bool {
    if (str.len < prefix.len) return false;
    if (!std.mem.eql(u8, str[0..prefix.len], prefix)) return false;
    return true;
}
