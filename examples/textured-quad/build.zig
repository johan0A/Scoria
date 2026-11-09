const std = @import("std");
const scoria = @import("scoria");
const zon = @import("build.zig.zon");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const scoria_dep = b.dependency("scoria", .{
        .target = target,
        .optimize = optimize,
    });
    root_module.addImport("scoria", scoria_dep.module("scoria"));

    const frag = scoria.compileSlangShader(scoria_dep, b, b.path("src/shaders/frag.slang"), "main", &.{.{
        .min_filter = .nearest,
        .mag_filter = .nearest,
        .mip_filter = .nearest,
    }});
    root_module.addAnonymousImport("frag.scir", .{ .root_source_file = frag });

    const vert = scoria.compileSlangShader(scoria_dep, b, b.path("src/shaders/vert.slang"), "main", &.{});
    root_module.addAnonymousImport("vert.scir", .{ .root_source_file = vert });

    {
        const sdl_dep = b.dependency("sdl", .{
            .target = target,
            .optimize = optimize,
        });
        const sdl_lib = sdl_dep.artifact("SDL3");
        root_module.linkLibrary(sdl_lib);

        const translate_c = b.addTranslateC(.{
            .root_source_file = b.addWriteFiles().add("stub.h",
                \\#include <SDL3/SDL.h>
                \\#include <SDL3/SDL_vulkan.h>
            ),
            .target = target,
            .optimize = optimize,
        });
        translate_c.addIncludePath(sdl_lib.getEmittedIncludeTree());
        root_module.addImport("c", translate_c.createModule());
    }

    {
        const exe = b.addExecutable(.{ .name = @tagName(zon.name), .root_module = root_module });
        b.installArtifact(exe);

        const run = b.addRunArtifact(exe);
        const run_step = b.step("run", "");
        run_step.dependOn(&run.step);
        run_step.dependOn(b.getInstallStep());
    }
}
