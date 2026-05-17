const std = @import("std");

const Solution = struct {
    day: u8,
    year: u16,
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const lib = b.addModule("boilerplate", .{
        .root_source_file = b.path("lib/boilerplate.zig"),
        .target = target,
    });

    const solutions = readSolutions(b) catch {
        std.debug.print("Failed to read solutions\n", .{});
        std.process.exit(1);
    };
    defer std.zon.parse.free(b.allocator, solutions);
    for (solutions) |solution| {
        const subpath = b.fmt("solutions/{}/day{}", .{ solution.year, solution.day });
        defer b.allocator.free(subpath);
        const name = b.fmt("{}-{}", .{ solution.year - 2000, solution.day });
        defer b.allocator.free(name);
        const desc = b.fmt("Solution for {} day {}", .{ solution.year, solution.day });
        defer b.allocator.free(desc);

        const dirpath = b.path(subpath);
        const mod = b.createModule(.{
            .root_source_file = dirpath.join(b.allocator, "src/main.zig") catch unreachable,
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "boilerplate", .module = lib },
            },
        });

        const exe = b.addExecutable(.{
            .name = name,
            .root_module = mod,
        });

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.addDirectoryArg(dirpath);
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step(name, desc);

        run_step.dependOn(&run_cmd.step);
    }
}

fn readSolutions(b: *std.Build) ![]const Solution {
    if (b.build_root.handle.readFileAllocOptions(
        b.graph.io,
        "solutions/solutions.zon",
        b.allocator,
        .unlimited,
        .@"1",
        0,
    )) |zon| {
        defer b.allocator.free(zon);
        return std.zon.parse.fromSliceAlloc([]const Solution, b.allocator, zon, null, .{});
    } else |err| {
        return err;
    }
}
