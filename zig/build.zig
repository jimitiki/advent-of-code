const std = @import("std");

const Solution = struct {
    day: u8,
    year: u16,
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("lib/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const lib = b.addLibrary(.{ .name = "lib", .root_module = lib_mod });
    b.installArtifact(lib);

    const add_mod = b.createModule(.{
        .root_source_file = b.path("add.zig"),
        .target = target,
        .optimize = optimize,
    });
    const add_exe = b.addExecutable(.{ .name = "add", .root_module = add_mod });
    const add_cmd = b.addRunArtifact(add_exe);
    add_cmd.addDirectoryArg(b.path(""));
    if (b.args) |args| {
        add_cmd.addArgs(args);
    }
    const add_step = b.step("add", "Create a new solution");
    add_step.dependOn(&add_cmd.step);

    const run_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    run_mod.addImport("lib", lib_mod);
    const exe = b.addExecutable(.{ .name = "advent", .root_module = run_mod });
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.addDirectoryArg(b.path("../inputs"));
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run a solution");
    run_step.dependOn(&run_cmd.step);
    run_step.dependOn(b.getInstallStep());

    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_module = run_mod,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
