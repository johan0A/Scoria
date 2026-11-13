const std = @import("std");
const sc = @import("sc_minimal.zig");
const SamplerDesc = @import("sampler_desc.zig").SamplerDesc;
const vk = @import("vulkan");

pub const to_sc = struct {
    pub fn format(fmt: vk.Format) ?sc.Format {
        inline for (comptime std.enums.values(sc.Format)) |sc_format| {
            if (fmt == comptime to_vk.format(sc_format)) return sc_format;
        }
        return null;
    }

    pub fn usageFlags(flags: vk.ImageUsageFlags) sc.TextureUsage {
        return .{
            .sampled = flags.sampled,
            .storage = flags.storage,
            .color_attachment = flags.color_attachment,
            .depth_stencil_attachment = flags.depth_stencil_attachment,
        };
    }

    pub fn presentMode(mode: vk.PresentModeKHR) ?sc.PresentMode {
        return switch (mode) {
            .immediate_khr => .immediate,
            .mailbox_khr => .mailbox,
            .fifo_khr => .fifo,
            .fifo_relaxed_khr => .fifo_relaxed,
            else => null,
        };
    }

    pub fn colorSpace(color_space: vk.ColorSpaceKHR) ?sc.ColorSpace {
        return switch (color_space) {
            .srgb_nonlinear_khr => .srgb_nonlinear,
            .extended_srgb_linear_ext => .scrgb_linear,
            else => null,
        };
    }

    pub fn adapterKind(device_type: vk.PhysicalDeviceType) sc.AdapterKind {
        return switch (device_type) {
            inline else => |t| @field(sc.AdapterKind, @tagName(t)),
            _ => .other,
        };
    }
};

pub const to_vk = struct {
    pub fn format(fmt: sc.Format) vk.Format {
        return switch (fmt) {
            .none => .undefined,
            .r8_unorm => .r8_unorm,
            .rg8_unorm => .r8g8_unorm,
            .rgba8_unorm => .r8g8b8a8_unorm,
            .r16_unorm => .r16_unorm,
            .rg16_unorm => .r16g16_unorm,
            .rgba16_unorm => .r16g16b16a16_unorm,
            .rgb10a2_unorm => .a2b10g10r10_unorm_pack32,
            .r16_float => .r16_sfloat,
            .rg16_float => .r16g16_sfloat,
            .rgba16_float => .r16g16b16a16_sfloat,
            .rg11b10_ufloat => .b10g11r11_ufloat_pack32,
            .rgba8_unorm_srgb => .r8g8b8a8_srgb,
            .bgra8_unorm => .b8g8r8a8_unorm,
            .bgra8_unorm_srgb => .b8g8r8a8_srgb,
            .r8_snorm => .r8_snorm,
            .rg8_snorm => .r8g8_snorm,
            .rgba8_snorm => .r8g8b8a8_snorm,
            .r16_snorm => .r16_snorm,
            .rg16_snorm => .r16g16_snorm,
            .rgba16_snorm => .r16g16b16a16_snorm,
            .rgb9e5_ufloat => .e5b9g9r9_ufloat_pack32,
            .r32_float => .r32_sfloat,
            .rg32_float => .r32g32_sfloat,
            .rgba32_float => .r32g32b32a32_sfloat,
            .r8_uint => .r8_uint,
            .r8_sint => .r8_sint,
            .rg8_uint => .r8g8_uint,
            .rg8_sint => .r8g8_sint,
            .rgba8_uint => .r8g8b8a8_uint,
            .rgba8_sint => .r8g8b8a8_sint,
            .r16_uint => .r16_uint,
            .r16_sint => .r16_sint,
            .rg16_uint => .r16g16_uint,
            .rg16_sint => .r16g16_sint,
            .rgba16_uint => .r16g16b16a16_uint,
            .rgba16_sint => .r16g16b16a16_sint,
            .r32_uint => .r32_uint,
            .r32_sint => .r32_sint,
            .rg32_uint => .r32g32_uint,
            .rg32_sint => .r32g32_sint,
            .rgba32_uint => .r32g32b32a32_uint,
            .rgba32_sint => .r32g32b32a32_sint,
            .rgb10a2_uint => .a2b10g10r10_uint_pack32,
            .depth16_unorm => .d16_unorm,
            .depth32_float => .d32_sfloat,
            .depth32_float_stencil8 => .d32_sfloat_s8_uint,
            .stencil8 => .s8_uint,
            .bc1_unorm => .bc1_rgba_unorm_block,
            .bc1_unorm_srgb => .bc1_rgba_srgb_block,
            .bc3_unorm => .bc3_unorm_block,
            .bc3_unorm_srgb => .bc3_srgb_block,
            .bc4_unorm => .bc4_unorm_block,
            .bc4_snorm => .bc4_snorm_block,
            .bc5_unorm => .bc5_unorm_block,
            .bc5_snorm => .bc5_snorm_block,
            .bc6h_ufloat => .bc6h_ufloat_block,
            .bc6h_float => .bc6h_sfloat_block,
            .bc7_unorm => .bc7_unorm_block,
            .bc7_unorm_srgb => .bc7_srgb_block,
            .astc_4x4_unorm => .astc_4x4_unorm_block,
            .astc_4x4_unorm_srgb => .astc_4x4_srgb_block,
            .astc_5x4_unorm => .astc_5x4_unorm_block,
            .astc_5x4_unorm_srgb => .astc_5x4_srgb_block,
            .astc_5x5_unorm => .astc_5x5_unorm_block,
            .astc_5x5_unorm_srgb => .astc_5x5_srgb_block,
            .astc_6x5_unorm => .astc_6x5_unorm_block,
            .astc_6x5_unorm_srgb => .astc_6x5_srgb_block,
            .astc_6x6_unorm => .astc_6x6_unorm_block,
            .astc_6x6_unorm_srgb => .astc_6x6_srgb_block,
            .astc_8x5_unorm => .astc_8x5_unorm_block,
            .astc_8x5_unorm_srgb => .astc_8x5_srgb_block,
            .astc_8x6_unorm => .astc_8x6_unorm_block,
            .astc_8x6_unorm_srgb => .astc_8x6_srgb_block,
            .astc_8x8_unorm => .astc_8x8_unorm_block,
            .astc_8x8_unorm_srgb => .astc_8x8_srgb_block,
            .astc_10x5_unorm => .astc_10x5_unorm_block,
            .astc_10x5_unorm_srgb => .astc_10x5_srgb_block,
            .astc_10x6_unorm => .astc_10x6_unorm_block,
            .astc_10x6_unorm_srgb => .astc_10x6_srgb_block,
            .astc_10x8_unorm => .astc_10x8_unorm_block,
            .astc_10x8_unorm_srgb => .astc_10x8_srgb_block,
            .astc_10x10_unorm => .astc_10x10_unorm_block,
            .astc_10x10_unorm_srgb => .astc_10x10_srgb_block,
            .astc_12x10_unorm => .astc_12x10_unorm_block,
            .astc_12x10_unorm_srgb => .astc_12x10_srgb_block,
            .astc_12x12_unorm => .astc_12x12_unorm_block,
            .astc_12x12_unorm_srgb => .astc_12x12_srgb_block,
        };
    }

    pub fn aspectsForFormat(fmt: sc.Format) vk.ImageAspectFlags {
        return switch (fmt) {
            .stencil8 => .{ .stencil = true },
            .depth16_unorm, .depth32_float => .{ .depth = true },
            .depth32_float_stencil8 => .{ .depth = true, .stencil = true },
            else => .{ .color = true },
        };
    }

    pub fn singleAspectForFormat(fmt: sc.Format) vk.ImageAspectFlags {
        var aspect_mask = aspectsForFormat(fmt);
        if (aspect_mask.depth) aspect_mask.stencil = false;
        return aspect_mask;
    }

    pub const Block = struct {
        width: u32 = 1,
        height: u32 = 1,
        size: u32,
    };

    pub fn blockForFormat(fmt: sc.Format) Block {
        return switch (fmt) {
            .none => unreachable,
            .r8_unorm, .r8_snorm, .r8_uint, .r8_sint, .stencil8 => .{ .size = 1 },
            .r16_unorm, .r16_snorm, .r16_uint, .r16_sint, .r16_float, .rg8_unorm, .rg8_snorm, .rg8_uint, .rg8_sint, .depth16_unorm => .{ .size = 2 },
            .r32_float, .r32_uint, .r32_sint, .rg16_unorm, .rg16_snorm, .rg16_uint, .rg16_sint, .rg16_float => .{ .size = 4 },
            .rgba8_unorm, .rgba8_unorm_srgb, .rgba8_snorm, .rgba8_uint, .rgba8_sint, .bgra8_unorm, .bgra8_unorm_srgb => .{ .size = 4 },
            .rgb10a2_uint, .rgb10a2_unorm, .rg11b10_ufloat, .rgb9e5_ufloat => .{ .size = 4 },
            .depth32_float, .depth32_float_stencil8 => .{ .size = 4 },
            .rg32_float, .rg32_uint, .rg32_sint, .rgba16_unorm, .rgba16_snorm, .rgba16_uint, .rgba16_sint, .rgba16_float => .{ .size = 8 },
            .rgba32_float, .rgba32_uint, .rgba32_sint => .{ .size = 16 },
            .bc1_unorm, .bc1_unorm_srgb, .bc4_unorm, .bc4_snorm => .{ .width = 4, .height = 4, .size = 8 },
            .bc3_unorm, .bc3_unorm_srgb, .bc5_unorm, .bc5_snorm => .{ .width = 4, .height = 4, .size = 16 },
            .bc6h_ufloat, .bc6h_float, .bc7_unorm, .bc7_unorm_srgb => .{ .width = 4, .height = 4, .size = 16 },
            .astc_4x4_unorm, .astc_4x4_unorm_srgb => .{ .width = 4, .height = 4, .size = 16 },
            .astc_5x4_unorm, .astc_5x4_unorm_srgb => .{ .width = 5, .height = 4, .size = 16 },
            .astc_5x5_unorm, .astc_5x5_unorm_srgb => .{ .width = 5, .height = 5, .size = 16 },
            .astc_6x5_unorm, .astc_6x5_unorm_srgb => .{ .width = 6, .height = 5, .size = 16 },
            .astc_6x6_unorm, .astc_6x6_unorm_srgb => .{ .width = 6, .height = 6, .size = 16 },
            .astc_8x5_unorm, .astc_8x5_unorm_srgb => .{ .width = 8, .height = 5, .size = 16 },
            .astc_8x6_unorm, .astc_8x6_unorm_srgb => .{ .width = 8, .height = 6, .size = 16 },
            .astc_8x8_unorm, .astc_8x8_unorm_srgb => .{ .width = 8, .height = 8, .size = 16 },
            .astc_10x5_unorm, .astc_10x5_unorm_srgb => .{ .width = 10, .height = 5, .size = 16 },
            .astc_10x6_unorm, .astc_10x6_unorm_srgb => .{ .width = 10, .height = 6, .size = 16 },
            .astc_10x8_unorm, .astc_10x8_unorm_srgb => .{ .width = 10, .height = 8, .size = 16 },
            .astc_10x10_unorm, .astc_10x10_unorm_srgb => .{ .width = 10, .height = 10, .size = 16 },
            .astc_12x10_unorm, .astc_12x10_unorm_srgb => .{ .width = 12, .height = 10, .size = 16 },
            .astc_12x12_unorm, .astc_12x12_unorm_srgb => .{ .width = 12, .height = 12, .size = 16 },
        };
    }

    pub fn topology(topo: sc.Topology) vk.PrimitiveTopology {
        return switch (topo) {
            .triangle_list => .triangle_list,
            .triangle_strip => .triangle_strip,
            .triangle_fan => .triangle_fan,
        };
    }

    pub fn presentMode(mode: sc.PresentMode) vk.PresentModeKHR {
        return switch (mode) {
            .immediate => .immediate_khr,
            .mailbox => .mailbox_khr,
            .fifo => .fifo_khr,
            .fifo_relaxed => .fifo_relaxed_khr,
        };
    }

    pub fn colorSpace(color_space: sc.ColorSpace) vk.ColorSpaceKHR {
        return switch (color_space) {
            .srgb_nonlinear => .srgb_nonlinear_khr,
            .scrgb_linear => .extended_srgb_linear_ext,
        };
    }

    pub fn pipelineStage(stage: sc.Stage) vk.PipelineStageFlags2 {
        var out: vk.PipelineStageFlags2 = .{};
        if (stage.transfer) out.all_transfer = true;
        if (stage.compute) out.compute_shader = true;
        if (stage.raster_color_out) out.color_attachment_output = true;
        if (stage.raster_depth_out) {
            out.early_fragment_tests = true;
            out.late_fragment_tests = true;
        }
        if (stage.pixel_shader) out.fragment_shader = true;
        if (stage.vertex_shader) {
            out.vertex_shader = true;
            out.index_input = true;
        }
        // TODO:
        // if (stage.mesh_shader) {
        //     out.task_shader_bit_ext = true;
        //     out.mesh_shader_bit_ext = true;
        // }
        return out;
    }

    pub fn textureDimension(tex: sc.TextureDimension) vk.ImageType {
        return switch (tex) {
            .@"1d" => .@"1d",
            .@"2d" => .@"2d",
            .@"3d" => .@"3d",
        };
    }

    pub fn usageFlags(flags: sc.TextureUsage) vk.ImageUsageFlags {
        return .{
            .transfer_src = true,
            .transfer_dst = true,
            .sampled = flags.sampled,
            .storage = flags.storage,
            .color_attachment = flags.color_attachment,
            .depth_stencil_attachment = flags.depth_stencil_attachment,
        };
    }

    pub fn viewType(tex: sc.TextureDimension, layer_count: u32) vk.ImageViewType {
        return switch (tex) {
            .@"1d" => if (layer_count > 1) .@"1d_array" else .@"1d",
            .@"2d" => if (layer_count > 1) .@"2d_array" else .@"2d",
            .@"3d" => .@"3d",
        };
    }

    pub fn extent3D(extent: sc.Extent3D) vk.Extent3D {
        return .{ .width = extent.width, .height = extent.height, .depth = extent.depth };
    }

    pub const view_format_count_max = @typeInfo(sc.Format).@"enum".field_names.len;

    pub fn imageCreateInfo(
        desc: sc.TextureDesc,
        format_list: *vk.ImageFormatListCreateInfo,
        view_formats: *[view_format_count_max]vk.Format,
    ) vk.ImageCreateInfo {
        const extra_formats = if (desc.view_formats.ptr) |ptr| ptr[0..desc.view_formats.count] else &.{};
        view_formats[0] = format(desc.format);
        for (extra_formats, view_formats[1..][0..extra_formats.len]) |extra_format, *view_format| view_format.* = format(extra_format);
        format_list.* = .{ .view_format_count = @intCast(extra_formats.len + 1), .p_view_formats = view_formats };
        return .{
            .p_next = if (extra_formats.len != 0) format_list else null,
            .flags = .{ .mutable_format = extra_formats.len != 0 },
            .image_type = textureDimension(desc.type),
            .format = format(desc.format),
            .extent = extent3D(desc.extent),
            .mip_levels = desc.mip_count,
            .array_layers = desc.layer_count,
            .samples = sampleCount(@intCast(desc.sample_count)),
            .tiling = .optimal,
            .usage = usageFlags(desc.usage),
            .sharing_mode = .exclusive,
            .initial_layout = .undefined,
        };
    }

    pub fn bufferUsage(memory: sc.MemoryKind) vk.BufferUsageFlags {
        return switch (memory) {
            .upload => .{
                .storage_buffer = true,
                .index_buffer = true,
                .indirect_buffer = true,
                .transfer_src = true,
                .shader_device_address = true,
                .resource_descriptor_buffer_ext = true,
            },
            .device_local => .{
                .storage_buffer = true,
                .index_buffer = true,
                .indirect_buffer = true,
                .transfer_src = true,
                .transfer_dst = true,
                .shader_device_address = true,
            },
            .readback => .{
                .storage_buffer = true,
                .transfer_dst = true,
                .shader_device_address = true,
            },
        };
    }

    pub fn indexType(index_type: sc.IndexType) vk.IndexType {
        return switch (index_type) {
            .uint16 => .uint16,
            .uint32 => .uint32,
        };
    }

    pub fn blendFactor(factor: sc.BlendFactor) vk.BlendFactor {
        return switch (factor) {
            .zero => .zero,
            .one => .one,
            .src_color => .src_color,
            .dst_color => .dst_color,
            .src_alpha => .src_alpha,
            .one_minus_src_color => .one_minus_src_color,
            .one_minus_src_alpha => .one_minus_src_alpha,
            .one_minus_dst_color => .one_minus_dst_color,
            .dst_alpha => .dst_alpha,
            .one_minus_dst_alpha => .one_minus_dst_alpha,
            .src_alpha_saturate => .src_alpha_saturate,
        };
    }

    pub fn blendOp(op: sc.BlendOp) vk.BlendOp {
        return switch (op) {
            .add => .add,
            .subtract => .subtract,
            .reverse_subtract => .reverse_subtract,
            .min => .min,
            .max => .max,
        };
    }

    pub fn colorBlendAttachment(blend_state: ?*const sc.BlendDesc, write_mask: sc.ColorWriteMask) vk.PipelineColorBlendAttachmentState {
        // the default blend state is equivalent to disabled blending
        const blend: sc.BlendDesc = if (blend_state) |b| b.* else .{};
        return .{
            .blend_enable = .fromBool(blend_state != null),
            .src_color_blend_factor = blendFactor(blend.color.src_factor),
            .dst_color_blend_factor = blendFactor(blend.color.dst_factor),
            .color_blend_op = blendOp(blend.color.op),
            .src_alpha_blend_factor = blendFactor(blend.alpha.src_factor),
            .dst_alpha_blend_factor = blendFactor(blend.alpha.dst_factor),
            .alpha_blend_op = blendOp(blend.alpha.op),
            .color_write_mask = writeMask(write_mask),
        };
    }

    pub fn attachmentLoadOp(op: sc.LoadOp) vk.AttachmentLoadOp {
        return switch (op) {
            .dont_care => .dont_care,
            .load => .load,
            .clear => .clear,
        };
    }

    pub fn attachmentStoreOp(op: sc.StoreOp) vk.AttachmentStoreOp {
        return switch (op) {
            .dont_care => .dont_care,
            .store => .store,
        };
    }

    pub fn isIntegerFormat(fmt: sc.Format) bool {
        return switch (fmt) {
            inline else => |f| comptime std.mem.endsWith(u8, @tagName(f), "int"),
        };
    }

    pub fn sampleCount(n: u8) vk.SampleCountFlags {
        return switch (n) {
            1 => .{ .@"1" = true },
            2 => .{ .@"2" = true },
            4 => .{ .@"4" = true },
            8 => .{ .@"8" = true },
            else => unreachable,
        };
    }

    pub fn writeMask(mask: sc.ColorWriteMask) vk.ColorComponentFlags {
        return .{
            .r = mask.r,
            .g = mask.g,
            .b = mask.b,
            .a = mask.a,
        };
    }

    pub fn cullMode(c: sc.Cull) vk.CullModeFlags {
        return switch (c) {
            .ccw => .{ .front = true },
            .cw => .{ .back = true },
            .all => .{ .front = true, .back = true },
            .none => .{},
        };
    }

    pub fn samplerCreateInfo(s: SamplerDesc) vk.SamplerCreateInfo {
        const mips_disabled = s.mip_filter == .none or s.coord == .pixel;
        return .{
            .flags = .{},
            .mag_filter = filter(s.mag_filter),
            .min_filter = filter(s.min_filter),
            .mipmap_mode = samplerMipmapMode(s.mip_filter),
            .address_mode_u = address(s.address.u),
            .address_mode_v = address(s.address.v),
            .address_mode_w = address(s.address.w),
            .mip_lod_bias = if (mips_disabled) 0 else s.lod_bias.toF32(),
            .anisotropy_enable = if (s.max_anisotropy != .x1) .true else .false,
            .max_anisotropy = anisotropy(s.max_anisotropy),
            .compare_enable = if (s.compare.enable) .true else .false,
            .compare_op = switch (s.compare.op) {
                inline else => |op| compareOp(@field(sc.CompareOp, @tagName(op))),
            },
            .min_lod = if (mips_disabled) 0 else s.lod_min.toF32(),
            .max_lod = if (mips_disabled) 0 else s.lod_max.toF32(),
            .border_color = switch (s.border_color) {
                .transparent_black => .float_transparent_black,
                .opaque_black => .float_opaque_black,
                .opaque_white => .float_opaque_white,
            },
            .unnormalized_coordinates = switch (s.coord) {
                .normalized => .false,
                .pixel => .true,
            },
        };
    }

    pub fn samplerReductionMode(r: SamplerDesc.Reduction) vk.SamplerReductionMode {
        return switch (r) {
            .weighted_average => .weighted_average,
            .minimum => .min,
            .maximum => .max,
        };
    }

    pub fn filter(f: SamplerDesc.Filter) vk.Filter {
        return switch (f) {
            .linear => .linear,
            .nearest => .nearest,
        };
    }

    pub fn address(f: SamplerDesc.Address) vk.SamplerAddressMode {
        return switch (f) {
            .repeat => .repeat,
            .mirrored_repeat => .mirrored_repeat,
            .clamp_to_edge => .clamp_to_edge,
            .clamp_to_border => .clamp_to_border,
        };
    }

    pub fn anisotropy(a: SamplerDesc.Anisotropy) f32 {
        return @floatFromInt(
            @as(u32, 1) << @backingInt(a),
        );
    }

    pub fn samplerMipmapMode(f: SamplerDesc.MipFilter) vk.SamplerMipmapMode {
        return switch (f) {
            .none => .nearest,
            .linear => .linear,
            .nearest => .nearest,
        };
    }

    pub fn stencilOp(op: sc.StencilOp) vk.StencilOp {
        return switch (op) {
            .keep => .keep,
            .zero => .zero,
            .replace => .replace,
            .increment_clamp => .increment_and_clamp,
            .decrement_clamp => .decrement_and_clamp,
            .invert => .invert,
            .increment_wrap => .increment_and_wrap,
            .decrement_wrap => .decrement_and_wrap,
        };
    }

    pub fn compareOp(op: sc.CompareOp) vk.CompareOp {
        return switch (op) {
            .never => .never,
            .less => .less,
            .equal => .equal,
            .less_equal => .less_or_equal,
            .greater => .greater,
            .not_equal => .not_equal,
            .greater_equal => .greater_or_equal,
            .always => .always,
        };
    }
};
