const std = @import("std");
const scoria = @import("scoria");
const zon = @import("build.zig.zon");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const scoria_dep = b.dependency("scoria", .{
        .target = target,
        .optimize = optimize,
    });
    const common_dep = b.dependency("common", .{
        .target = target,
        .optimize = optimize,
    });

    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "scoria", .module = scoria_dep.module("scoria") },
            .{ .name = "common", .module = common_dep.module("common") },
            .{ .name = "c", .module = common_dep.module("c") },
        },
    });

    const compute = scoria.compileSlangShader(scoria_dep, b, b.path("src/shaders/generate_texture.slang"), "main", &.{});
    root_module.addAnonymousImport("generate_texture.scir", .{ .root_source_file = compute });

    const exe = b.addExecutable(.{ .name = @tagName(zon.name), .root_module = root_module });
    b.installArtifact(exe);

    const run = b.addRunArtifact(exe);
    const run_step = b.step("run", "");
    run_step.dependOn(&run.step);
    run_step.dependOn(b.getInstallStep());
}
