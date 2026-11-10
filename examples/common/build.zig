const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const sdl_lib = b.dependency("sdl", .{
        .target = target,
        .optimize = optimize,
    }).artifact("SDL3");

    const translate_c = b.addTranslateC(.{
        .root_source_file = b.addWriteFiles().add("stub.h", "#include <SDL3/SDL.h>\n"),
        .target = target,
        .optimize = optimize,
    });
    translate_c.addIncludePath(sdl_lib.getEmittedIncludeTree());
    const c = translate_c.addModule("c");
    c.linkLibrary(sdl_lib);

    const scoria_dep = b.dependency("scoria", .{
        .target = target,
        .optimize = optimize,
    });
    _ = b.addModule("common", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "scoria", .module = scoria_dep.module("scoria") },
            .{ .name = "c", .module = c },
        },
    });
}
