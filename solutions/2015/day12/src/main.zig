const std = @import("std");

const Part = @import("lib").Part;

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    defer arena.free(args);
    const part = std.meta.stringToEnum(Part, args[2]);

    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer: std.Io.File.Writer = .init(.stdout(), init.io, &stdout_buffer);
    var stdout = &stdout_writer.interface;

    const dir = try std.Io.Dir.openDirAbsolute(init.io, args[1], .{});
    const subpath = try std.fmt.allocPrint(arena, "data/{s}.txt", .{args[3]});
    const json = try dir.readFileAlloc(init.io, subpath, arena, .unlimited);
    const parsed = try std.json.parseFromSliceLeaky(std.json.Value, arena, json, .{});

    try stdout.print("{}\n", .{try sumJsonValue(parsed, part == .p2)});
    try stdout.flush();
}

fn sumJsonValue(value: std.json.Value, exclude_red: bool) !i64 {
    switch (value) {
        .float => return error.InvalidInput,
        .integer => |i| return i,
        .array => |a| {
            var sum: i64 = 0;
            for (a.items) |v| {
                sum += try sumJsonValue(v, exclude_red);
            }
            return sum;
        },
        .object => |o| {
            var sum: i64 = 0;
            for (o.values()) |v| {
                if (exclude_red) {
                    switch (v) {
                        .string => |s| if (std.mem.eql(u8, s, "red")) {
                            return 0;
                        },
                        else => {},
                    }
                }
                sum += try sumJsonValue(v, exclude_red);
            }
            return sum;
        },
        else => return 0,
    }
}
