const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "3d-renderer",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const glfw_dep = b.dependency("mach_glfw", .{
        .target = target,
        .optimize = optimize,
    });

    // glfw
    exe.addModule("mach-glfw", glfw_dep.module("mach-glfw"));
    @import("mach_glfw").link(glfw_dep.builder, exe);

    // opengl
    exe.addModule("opengl", b.createModule(.{
        .source_file = .{ .path = "lib/opengl/bindings.zig" },
    }));

    // stb
    exe.addIncludePath(.{ .path = "lib/stb/c" });
    exe.addCSourceFile(.{
        .file = .{ .path = "lib/stb/c/stb_image.c" },
        .flags = &.{ "-std=c99", "-fno-sanitize=undefined" },
    });
    exe.addModule("stb", b.createModule(.{
        .source_file = .{ .path = "lib/stb/stb.zig" },
    }));

    // zmath
    exe.addModule("zmath", b.createModule(.{
        .source_file = .{ .path = "lib/zmath/main.zig" },
    }));

    // zmesh
    const zmesh = @import("lib/zmesh/build.zig");
    const zmesh_pkg = zmesh.package(b, target, optimize, .{});
    zmesh_pkg.link(exe);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
