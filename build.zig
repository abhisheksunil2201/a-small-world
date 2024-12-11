const std = @import("std");
const Build = std.Build;
const OptimizeMode = std.builtin.OptimizeMode;
const sokol = @import("sokol");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
    });
    // special case handling for native vs web build
    if (target.result.isWasm()) {
        try buildWeb(b, target, optimize, dep_sokol);
    } else {
        try buildNative(b, target, optimize, dep_sokol);
    }
}

fn buildNative(b: *Build, target: Build.ResolvedTarget, optimize: OptimizeMode, dep_sokol: *Build.Dependency) !void {
    const a_small_world = b.addExecutable(.{
        .name = "a-small-world",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/a-small-world.zig"),
    });
    a_small_world.root_module.addImport("sokol", dep_sokol.module("sokol"));
    b.installArtifact(a_small_world);
    const run = b.addRunArtifact(a_small_world);
    b.step("run", "Run a-small-world").dependOn(&run.step);
}

// for web builds, the Zig code needs to be built into a library and linked with the Emscripten linker
fn buildWeb(b: *Build, target: Build.ResolvedTarget, optimize: OptimizeMode, dep_sokol: *Build.Dependency) !void {
    const a_small_world = b.addStaticLibrary(.{
        .name = "a-small-world",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/a-small-world.zig"),
    });
    a_small_world.root_module.addImport("sokol", dep_sokol.module("sokol"));

    // create a build step which invokes the Emscripten linker
    const emsdk = dep_sokol.builder.dependency("emsdk", .{});
    const link_step = try sokol.emLinkStep(b, .{
        .lib_main = a_small_world,
        .target = target,
        .optimize = optimize,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = false,
        .shell_file_path = dep_sokol.path("src/sokol/web/shell.html"),
    });
    // ...and a special run step to start the web build output via 'emrun'
    const run = sokol.emRunStep(b, .{ .name = "a-small-world", .emsdk = emsdk });
    run.step.dependOn(&link_step.step);
    b.step("run", "Run a-small-world").dependOn(&run.step);
}
