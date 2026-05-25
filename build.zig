const std = @import("std");

const Solution = struct {
    day: u8,
    year: u16,
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const lib = b.addModule("lib", .{
        .root_source_file = b.path("lib/root.zig"),
        .target = target,
    });

    {
        const mod = b.createModule(.{
            .root_source_file = b.path("add.zig"),
            .target = target,
            .optimize = optimize,
        });
        const exe = b.addExecutable(.{ .name = "add", .root_module = mod });
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.addDirectoryArg(b.path(""));
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step("add", "Create a new solution");
        run_step.dependOn(&run_cmd.step);
    }

    const solutions = readSolutions(b) catch {
        std.debug.print("Failed to read solutions\n", .{});
        std.process.exit(1);
    };
    defer std.zon.parse.free(b.allocator, solutions);
    for (solutions) |solution| {
        const srcpath = b.fmt("src/y{}/d{:0>2}.zig", .{ solution.year - 2000, solution.day });
        defer b.allocator.free(srcpath);
        const name = b.fmt("{}-{}", .{ solution.year - 2000, solution.day });
        defer b.allocator.free(name);
        const desc = b.fmt("Solution for {} day {}", .{ solution.year, solution.day });
        defer b.allocator.free(desc);
        const datapath = b.fmt("inputs/y{}", .{solution.year - 2000});

        const mod = b.createModule(.{
            .root_source_file = b.path(srcpath),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "lib", .module = lib },
            },
        });

        const exe = b.addExecutable(.{
            .name = name,
            .root_module = mod,
        });

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.addDirectoryArg(b.path(datapath));
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
        "solutions.zon",
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
