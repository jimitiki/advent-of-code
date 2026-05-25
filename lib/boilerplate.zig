const std = @import("std");

pub const Part = enum {
    p1,
    p2,
};

pub const Boilerplate = struct {
    io: std.Io,
    arena: std.mem.Allocator,
    args: []const [:0]const u8,
    input_file: std.Io.File,
    input_reader: std.Io.File.Reader,
    stdout_writer: std.Io.File.Writer,
    part: Part,

    pub fn init(std_init: std.process.Init, stdout_buf: []u8, input_buf: []u8) !Boilerplate {
        const arena = std_init.arena.allocator();
        const args = try std_init.minimal.args.toSlice(arena);
        const file_path = try std.fmt.allocPrint(arena, "{s}/{s}.txt", .{ args[1], args[3] });
        const input_file = try std.Io.Dir.cwd().openFile(std_init.io, file_path, .{});
        const stdout_writer: std.Io.File.Writer = .init(.stdout(), std_init.io, stdout_buf);
        return .{
            .io = std_init.io,
            .arena = arena,
            .args = args,
            .input_file = input_file,
            .input_reader = input_file.reader(std_init.io, input_buf),
            .stdout_writer = stdout_writer,
            .part = std.meta.stringToEnum(Part, args[2]) orelse return error.InvalidAlgorithm,
        };
    }

    pub fn deinit(self: *Boilerplate) void {
        self.input_file.close(self.io);
    }
};
