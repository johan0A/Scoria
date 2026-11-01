const std = @import("std");
pub const SamplerDesc = @import("src/sampler_desc.zig").SamplerDesc;

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const validation_layers = b.option(bool, "validation-layers", "") orelse (optimize == .debug);

    const lib = b.addLibrary(.{
        .name = "sulfur",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/loader.zig"),
            .optimize = optimize,
            .target = target,
            .link_libc = switch (target.result.os.tag) {
                .windows => false,
                else => true,
            },
        }),
    });
    b.installArtifact(lib);

    const root_module = b.addModule("sulfur", .{
        .root_source_file = b.path("src/sf.zig"),
        .optimize = optimize,
        .target = target,
    });
    root_module.linkLibrary(lib);

    var options = b.addOptions();
    options.addOption(bool, "validation_layers", validation_layers);
    lib.root_module.addOptions("options", options);

    const vulkan_headers_dep = b.dependency("vulkan_headers", .{});

    const vulkan = b.dependency("vulkan", .{
        .registry = vulkan_headers_dep.path("registry/vk.xml"),
    });
    lib.root_module.addImport("vulkan", vulkan.module("vulkan-zig"));

    {
        const generate_sf_bindings = b.step("generate-sf-bindings", "");

        const generate_sf_bindings_exe = b.addExecutable(.{
            .name = "generate-sf-bindings",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/render_zig_bindings.zig"),
                .optimize = .Debug,
                .target = b.graph.host,
            }),
        });
        const generate_bindings_minimal = b.addRunArtifact(generate_sf_bindings_exe);
        generate_bindings_minimal.addArg("--bindings_minimal");
        generate_bindings_minimal.addFileArg(b.path("src/sulfur.json"));
        const bindings_minimal = generate_bindings_minimal.addOutputFileArg("sf_minimal.zig");

        const generate_bindings = b.addRunArtifact(generate_sf_bindings_exe);
        generate_bindings.addArg("--bindings");
        generate_bindings.addFileArg(b.path("src/sulfur.json"));
        const bindings = generate_bindings.addOutputFileArg("sf.zig");

        const generate_driver_symbol_map = b.addRunArtifact(generate_sf_bindings_exe);
        generate_driver_symbol_map.addArg("--driver_symbol_map");
        generate_driver_symbol_map.addFileArg(b.path("src/sulfur.json"));
        const driver_symbol_map = generate_driver_symbol_map.addOutputFileArg("driver_symbol_map.zig");

        const generate_loader_symbol_map = b.addRunArtifact(generate_sf_bindings_exe);
        generate_loader_symbol_map.addArg("--loader_symbol_map");
        generate_loader_symbol_map.addFileArg(b.path("src/sulfur.json"));
        const loader_symbol_map = generate_loader_symbol_map.addOutputFileArg("loader_symbol_map.zig");

        const update_source_files = b.addUpdateSourceFiles();
        update_source_files.addCopyFileToSource(bindings_minimal, "src/sf_minimal.zig");
        update_source_files.addCopyFileToSource(bindings, "src/sf.zig");
        update_source_files.addCopyFileToSource(driver_symbol_map, "src/driver_symbol_map.zig");
        update_source_files.addCopyFileToSource(loader_symbol_map, "src/loader_symbol_map.zig");
        generate_sf_bindings.dependOn(&update_source_files.step);
    }

    {
        const tests = b.addTest(.{ .name = "test", .root_module = root_module });
        const run_tests = b.addRunArtifact(tests);
        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_tests.step);
    }
}

pub fn compileShader(
    sulfur_dep: *std.Build.Dependency,
    b: *std.Build,
    src: std.Build.LazyPath,
    entry: []const u8,
    samplers: []const SamplerDesc,
) std.Build.LazyPath {
    const command = b.addSystemCommand(&.{
        "slangc",
        "-target",
        "spirv",
        "-profile",
        "spirv_1_6",
        "-fvk-use-c-layout",
        "-entry",
        entry,
    });
    command.addFileArg(src);
    command.addArg("-o");
    const spirv = command.addOutputFileArg("shader.spv");

    const sfir = b.addExecutable(.{
        .name = "sfir",
        .root_module = b.createModule(.{
            .root_source_file = sulfur_dep.path("src/sfir.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });
    const run_sfir = b.addRunArtifact(sfir);

    const shader = run_sfir.addOutputFileArg("shader.sfir");
    run_sfir.addFileArg(spirv);
    for (samplers) |sampler| {
        const as_int: u64 = @bitCast(sampler);
        run_sfir.addArg(&std.fmt.hex(as_int));
    }

    return shader;
}
