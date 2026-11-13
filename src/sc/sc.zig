const std = @import("std");
const target = @import("builtin").target;
const functions = @import("functions.zig");
pub const heap = @import("heap.zig");

pub const PointerAttributes = heap.PointerAttributes;
pub const PointerInfo = heap.PointerInfo;
pub const Ptr = heap.Ptr;
pub const SliceInfo = heap.SliceInfo;
pub const Slice = heap.Slice;
pub const DeviceAllocator = heap.DeviceAllocator;

pub const @"callconv": std.lang.CallingConvention = switch (target.os.tag) {
    .windows => if (target.cpu.arch == .x86) .{ .x86_stdcall = .{} } else .c,
    else => .c,
};

pub const descriptor_size_max: usize = 64;
pub const adapter_name_capacity_bytes: usize = 256;

pub const DeviceAddress = u64;

pub const Instance = opaque {
    pub const create = functions.createInstance;
    pub const destroy = functions.destroyInstance;
    pub const enumerateAdapters = functions.enumerateAdapters;
    pub const enumerateAdaptersAlloc = functions.enumerateAdaptersAlloc;
    pub const createDevice = functions.createDevice;
    pub const adapterInfo = functions.adapterInfo;
};

pub const Surface = opaque {
    pub const createWin32 = functions.createSurfaceWin32;
    pub const createXlib = functions.createSurfaceXlib;
    pub const destroy = functions.destroySurface;
    pub const supportedUsage = functions.surfaceSupportedUsage;
    pub const supportedFormats = functions.surfaceSupportedFormats;
    pub const supportedFormatsAlloc = functions.surfaceSupportedFormatsAlloc;
    pub const presentModes = functions.surfacePresentModes;
    pub const presentModesAlloc = functions.surfacePresentModesAlloc;
};

pub const Adapter = opaque {};

pub const Device = opaque {
    pub const create = functions.createDevice;
    pub const destroy = functions.destroyDevice;
    pub const createSurfaceWin32 = functions.createSurfaceWin32;
    pub const createSurfaceXlib = functions.createSurfaceXlib;
    pub const hostFromPointer = functions.hostFromDevicePointer;
    pub const alloc = functions.alloc;
    pub const free = functions.free;
    pub const descriptorSizeAndHeapAlign = functions.descriptorSizeAndHeapAlign;
    pub const storeDescriptor = functions.storeDescriptor;
    pub const getQueue = functions.getQueue;
    pub const createTimeline = functions.createTimeline;
    pub const textureSizeAlign = functions.textureSizeAlign;
    pub const textureSampleCountMax = functions.textureSampleCountMax;
    pub const createTexture = functions.createTexture;
    pub const createComputePipeline = functions.createComputePipeline;
    pub const createGraphicsPipeline = functions.createGraphicsPipeline;
    pub const createDepthStencilState = functions.createDepthStencilState;
};

pub const Queue = opaque {
    pub const textureCopyGranularity = functions.textureCopyGranularity;
    pub const createCommandPool = functions.createCommandPool;
    pub const submit = functions.submit;
    pub const submitAndSignal = functions.submitAndSignal;
    pub const createSwapchain = functions.createSwapchain;
};

pub const Timeline = opaque {
    pub const create = functions.createTimeline;
    pub const destroy = functions.destroyTimeline;

    pub fn wait(timeline: *Timeline, value: u64) !void {
        return functions.waitTimelinePoint(.{ .timeline = timeline, .value = value });
    }
};

pub const Swapchain = opaque {
    pub const create = functions.createSwapchain;
    pub const destroy = functions.destroySwapchain;
    pub const acquireBackBuffer = functions.acquireBackBuffer;
    pub const present = functions.present;
};

pub const CommandPool = opaque {
    pub const create = functions.createCommandPool;
    pub const destroy = functions.destroyCommandPool;
    pub const reset = functions.resetCommandPool;
    pub const startCommandRecording = functions.startCommandRecording;
};

pub const CommandBuffer = opaque {
    pub const setActiveTextureHeap = functions.setActiveTextureHeap;
    pub const setDepthStencilState = functions.setDepthStencilState;
    pub const setPipeline = functions.setPipeline;
    pub const dispatch = functions.dispatch;
    pub const dispatchIndirect = functions.dispatchIndirect;
    pub const barrier = functions.barrier;
    pub const copyTextureToMemory = functions.copyTextureToMemory;
    pub const copyMemoryToTexture = functions.copyMemoryToTexture;
    pub const beginRenderPass = functions.beginRenderPass;
    pub const endRenderPass = functions.endRenderPass;
    pub const setScissor = functions.setScissor;
    pub const setViewport = functions.setViewport;
    pub const draw = functions.draw;
    pub const drawIndexed = functions.drawIndexed;
    pub const drawIndexedInstanced = functions.drawIndexedInstanced;
    pub const drawIndexedInstancedIndirect = functions.drawIndexedInstancedIndirect;
    pub const drawIndirect = functions.drawIndirect;

    pub fn copyMemory(command_buffer: *CommandBuffer, comptime T: type, source: Slice(T, .{}), destination: Slice(T, .{})) void {
        functions.copyMemory(command_buffer, .ptrCast(source), .ptrCast(destination));
    }
};

pub const Texture = opaque {
    pub const create = functions.createTexture;
    pub const destroy = functions.destroyTexture;
    pub const storageDescriptor = functions.textureStorageDescriptor;
    pub const viewDescriptor = functions.textureViewDescriptor;
};

pub const Pipeline = opaque {
    pub const createCompute = functions.createComputePipeline;
    pub const createGraphics = functions.createGraphicsPipeline;
    pub const destroy = functions.destroyPipeline;
};

pub const DepthStencilState = opaque {
    pub const create = functions.createDepthStencilState;
    pub const destroy = functions.destroyDepthStencilState;
};

pub const Result = enum(u32) {
    ok = 0,
    unknown = 1,
    out_of_memory = 2,
    out_of_device_memory = 3,
    device_lost = 4,
    surface_lost = 5,
    no_backbuffer = 6,
    malformed_scir = 7,
    unsupported_scir_version = 8,
    unsupported_scir_bytecode = 9,
};

pub const MemoryKind = enum(u32) {
    upload = 0,
    device_local = 1,
    readback = 2,
};

pub const AdapterKind = enum(u32) {
    other = 0,
    integrated_gpu = 1,
    discrete_gpu = 2,
    virtual_gpu = 3,
    cpu = 4,
};

pub const PresentMode = enum(u32) {
    immediate = 0,
    mailbox = 1,
    fifo = 2,
    fifo_relaxed = 3,
};

pub const ColorSpace = enum(u32) {
    /// sRGB primaries, sRGB transfer function. 1.0 is SDR white.
    srgb_nonlinear = 0,
    /// HDR. sRGB primaries, linear. 1.0 is 80 nits, values outside [0, 1] reach wider gamut and higher luminance.
    scrgb_linear = 1,
};

pub const CompareOp = enum(u32) {
    always = 0,
    never = 1,
    less = 2,
    less_equal = 3,
    greater = 4,
    greater_equal = 5,
    equal = 6,
    not_equal = 7,
};

pub const QueueKind = enum(u32) {
    graphics = 0,
    compute = 1,
    transfer = 2,
};

pub const LoadOp = enum(u32) {
    load = 0,
    clear = 1,
    dont_care = 2,
};

pub const StoreOp = enum(u32) {
    store = 0,
    dont_care = 1,
};

pub const IndexType = enum(u32) {
    uint16 = 0,
    uint32 = 1,
};

pub const TextureDimension = enum(u32) {
    @"2d" = 0,
    @"3d" = 1,
    @"1d" = 2,
};

pub const Topology = enum(u32) {
    triangle_list = 0,
    triangle_strip = 1,
    triangle_fan = 2,
};

pub const Cull = enum(u32) {
    none = 0,
    all = 1,
    ccw = 2,
    cw = 3,
};

pub const BlendOp = enum(u32) {
    add = 0,
    subtract = 1,
    reverse_subtract = 2,
    min = 3,
    max = 4,
};

pub const BlendFactor = enum(u32) {
    zero = 0,
    one = 1,
    src_color = 2,
    dst_color = 3,
    src_alpha = 4,
    one_minus_src_color = 5,
    one_minus_src_alpha = 6,
    one_minus_dst_color = 7,
    dst_alpha = 8,
    one_minus_dst_alpha = 9,
    src_alpha_saturate = 10,
};

/// Formats are ordered by class. Every adapter provides the capabilities of the class:
/// S sampled, F linear filtering, R render target, B blending, M multisampling, W storage.
/// - `.r8_unorm` to `.rg11b10_ufloat`: S F R B M W
/// - `.rgba8_unorm_srgb` to `.bgra8_unorm_srgb`: S F R B M
/// - `.r8_snorm` to `.rgba16_snorm`: S F W
/// - `.rgb9e5_ufloat`: S F
/// - `.r32_float` to `.rgba32_float`: S R M W, F B with `FormatFeatures.float32_filtering_blending`
/// - `.r8_uint` to `.rgb10a2_uint`: S R M W
/// - `.depth16_unorm` to `.stencil8`: S R M, the depth aspect also supports comparison sampling
/// - `.bc1_unorm` to `.bc7_unorm_srgb`: S F, 4x4 blocks, requires `FormatFeatures.bc`
/// - `.astc_4x4_unorm` to `.astc_12x12_unorm_srgb`: S F, requires `FormatFeatures.astc`
pub const Format = enum(u32) {
    none = 0,
    r8_unorm = 1,
    rg8_unorm = 2,
    rgba8_unorm = 3,
    r16_unorm = 4,
    rg16_unorm = 5,
    rgba16_unorm = 6,
    rgb10a2_unorm = 7,
    r16_float = 8,
    rg16_float = 9,
    rgba16_float = 10,
    rg11b10_ufloat = 11,
    rgba8_unorm_srgb = 12,
    bgra8_unorm = 13,
    bgra8_unorm_srgb = 14,
    r8_snorm = 15,
    rg8_snorm = 16,
    rgba8_snorm = 17,
    r16_snorm = 18,
    rg16_snorm = 19,
    rgba16_snorm = 20,
    rgb9e5_ufloat = 21,
    r32_float = 22,
    rg32_float = 23,
    rgba32_float = 24,
    r8_uint = 25,
    r8_sint = 26,
    rg8_uint = 27,
    rg8_sint = 28,
    rgba8_uint = 29,
    rgba8_sint = 30,
    r16_uint = 31,
    r16_sint = 32,
    rg16_uint = 33,
    rg16_sint = 34,
    rgba16_uint = 35,
    rgba16_sint = 36,
    r32_uint = 37,
    r32_sint = 38,
    rg32_uint = 39,
    rg32_sint = 40,
    rgba32_uint = 41,
    rgba32_sint = 42,
    rgb10a2_uint = 43,
    depth16_unorm = 44,
    depth32_float = 45,
    depth32_float_stencil8 = 46,
    /// Also selects the stencil aspect of `.depth32_float_stencil8` in views and copies.
    stencil8 = 47,
    bc1_unorm = 48,
    bc1_unorm_srgb = 49,
    bc3_unorm = 50,
    bc3_unorm_srgb = 51,
    bc4_unorm = 52,
    bc4_snorm = 53,
    bc5_unorm = 54,
    bc5_snorm = 55,
    bc6h_ufloat = 56,
    bc6h_float = 57,
    bc7_unorm = 58,
    bc7_unorm_srgb = 59,
    astc_4x4_unorm = 60,
    astc_4x4_unorm_srgb = 61,
    astc_5x4_unorm = 62,
    astc_5x4_unorm_srgb = 63,
    astc_5x5_unorm = 64,
    astc_5x5_unorm_srgb = 65,
    astc_6x5_unorm = 66,
    astc_6x5_unorm_srgb = 67,
    astc_6x6_unorm = 68,
    astc_6x6_unorm_srgb = 69,
    astc_8x5_unorm = 70,
    astc_8x5_unorm_srgb = 71,
    astc_8x6_unorm = 72,
    astc_8x6_unorm_srgb = 73,
    astc_8x8_unorm = 74,
    astc_8x8_unorm_srgb = 75,
    astc_10x5_unorm = 76,
    astc_10x5_unorm_srgb = 77,
    astc_10x6_unorm = 78,
    astc_10x6_unorm_srgb = 79,
    astc_10x8_unorm = 80,
    astc_10x8_unorm_srgb = 81,
    astc_10x10_unorm = 82,
    astc_10x10_unorm_srgb = 83,
    astc_12x10_unorm = 84,
    astc_12x10_unorm_srgb = 85,
    astc_12x12_unorm = 86,
    astc_12x12_unorm_srgb = 87,
};

pub const StencilOp = enum(u32) {
    keep = 0,
    zero = 1,
    replace = 2,
    increment_clamp = 3,
    decrement_clamp = 4,
    invert = 5,
    increment_wrap = 6,
    decrement_wrap = 7,
};

pub const Stage = packed struct(u32) {
    transfer: bool = false,
    compute: bool = false,
    raster_color_out: bool = false,
    raster_depth_out: bool = false,
    pixel_shader: bool = false,
    vertex_shader: bool = false,
    padding: u26 = 0,

    pub const all: Stage = .{
        .transfer = true,
        .compute = true,
        .raster_color_out = true,
        .raster_depth_out = true,
        .pixel_shader = true,
        .vertex_shader = true,
    };
};

pub const Hazard = packed struct(u32) {
    draw_arguments: bool = false,
    descriptors: bool = false,
    depth_stencil: bool = false,
    padding: u29 = 0,
};

pub const TextureUsage = packed struct(u32) {
    sampled: bool = false,
    storage: bool = false,
    color_attachment: bool = false,
    depth_stencil_attachment: bool = false,
    padding: u28 = 0,
};

/// Format capabilities beyond the guarantees of `Format`. At least one of `bc` and `astc` is always available.
pub const FormatFeatures = packed struct(u32) {
    /// `.r32_float` to `.rgba32_float` support linear filtering and blending.
    float32_filtering_blending: bool = false,
    /// `.bc1_unorm` to `.bc7_unorm_srgb` are available.
    bc: bool = false,
    /// `.astc_4x4_unorm` to `.astc_12x12_unorm_srgb` are available.
    astc: bool = false,
    padding: u29 = 0,
};

pub const ColorWriteMask = packed struct(u32) {
    r: bool = false,
    g: bool = false,
    b: bool = false,
    a: bool = false,
    padding: u28 = 0,

    pub const all: ColorWriteMask = .{
        .r = true,
        .g = true,
        .b = true,
        .a = true,
    };
};

pub const DepthFlags = packed struct(u32) {
    read: bool = false,
    write: bool = false,
    padding: u30 = 0,

    pub const read_write: DepthFlags = .{
        .read = true,
        .write = true,
    };
};

pub const AllocFn = *const fn (
    user_data: *anyopaque,
    size_bytes: usize,
    alignment: usize,
) callconv(@"callconv") ?[*]u8;

pub const RemapFn = *const fn (
    user_data: *anyopaque,
    pointer: [*]u8,
    size_bytes: usize,
    alignment: usize,
    new_size_bytes: usize,
) callconv(@"callconv") ?[*]u8;

pub const FreeFn = *const fn (
    user_data: *anyopaque,
    pointer: [*]u8,
    size_bytes: usize,
    alignment: usize,
) callconv(@"callconv") void;

pub const Symbol = *const fn (
    name: [*:0]const u8,
) callconv(@"callconv") ?*const anyopaque;

pub const HostAllocator = extern struct {
    user_data: *anyopaque,
    alloc: AllocFn,
    remap: RemapFn,
    free: FreeFn,
};

pub const Extent2D = extern struct {
    width: u32,
    height: u32,
};

pub const Extent3D = extern struct {
    width: u32,
    height: u32,
    depth: u32,
};

pub const Offset2D = extern struct {
    x: i32 = 0,
    y: i32 = 0,
};

pub const Offset3D = extern struct {
    x: i32 = 0,
    y: i32 = 0,
    z: i32 = 0,
};

pub const Rect2D = extern struct {
    offset: Offset2D = .{},
    extent: Extent2D,
};

pub const Viewport = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    width: f32,
    height: f32,
    min_depth: f32 = 0,
    max_depth: f32 = 1,
};

pub const DepthBias = extern struct {
    constant: f32 = 0,
    clamp: f32 = 0,
    slope: f32 = 0,
};

pub const SizeAlign = extern struct {
    size: usize,
    alignment_byte_units: usize,

    pub fn alignment(size_align: SizeAlign) std.mem.Alignment {
        return .fromByteUnits(size_align.alignment_byte_units);
    }
};

pub const AdapterInfo = extern struct {
    /// UTF-8, null-terminated.
    name: [adapter_name_capacity_bytes]u8,
    kind: AdapterKind,
    format_features: FormatFeatures,
};

pub const SurfaceWin32Desc = extern struct {
    hinstance: *anyopaque,
    hwnd: *anyopaque,
};

pub const SurfaceXlibDesc = extern struct {
    display: *anyopaque,
    window: u64,
};

pub const HostDeviceAddress = extern struct {
    host: *anyopaque,
    device: Ptr(.many, u8, .{}),
};

pub const SwapchainDesc = extern struct {
    format: Format,
    /// format must be supported by the surface for this color space.
    color_space: ColorSpace = .srgb_nonlinear,
    present_mode: PresentMode,
    usage: TextureUsage,
    /// Acquiring a back buffer blocks until the present from this many frames ago is displayed. 1 gives the lowest latency, 0 disables the wait. Ignored when the platform cannot report presentation.
    frame_latency_max: u32 = 0,
};

pub const BackBuffer = extern struct {
    texture: *Texture,
    extent: Extent2D,
};

pub const TimelinePoint = extern struct {
    timeline: *Timeline,
    value: u64,

    pub const wait = functions.waitTimelinePoint;
};

pub const DepthAttachment = extern struct {
    texture: ?*Texture = null,
    load_op: LoadOp = .load,
    store_op: StoreOp = .store,
    clear_value: f32 = 1,
};

pub const StencilAttachment = extern struct {
    texture: ?*Texture = null,
    load_op: LoadOp = .load,
    store_op: StoreOp = .store,
    clear_value: u32 = 0,
};

pub const ColorAttachment = extern struct {
    texture: *Texture,
    load_op: LoadOp = .load,
    store_op: StoreOp = .store,
    clear_color: [4]f32 = .{ 0, 0, 0, 1 },
    /// Single-sampled texture of the same format and extent that the samples of texture are resolved into when the render pass ends. Samples are averaged, integer formats take the first sample.
    resolve_texture: ?*Texture = null,
};

pub const ColorAttachments = extern struct {
    count: u32 = 0,
    ptr: ?[*]const ColorAttachment = null,

    pub fn fromSlice(slice: []const ColorAttachment) ColorAttachments {
        return .{ .count = @intCast(slice.len), .ptr = slice.ptr };
    }
};

pub const RenderPassDesc = extern struct {
    depth_attachment: DepthAttachment = .{},
    stencil_attachment: StencilAttachment = .{},
    color_attachments: ColorAttachments = .{},
};

pub const DrawIndexedArguments = extern struct {
    index_count: u32,
    instance_count: u32 = 1,
    first_index: u32 = 0,
    vertex_offset: i32 = 0,
    first_instance: u32 = 0,
};

pub const DrawArguments = extern struct {
    vertex_count: u32,
    instance_count: u32 = 1,
    first_vertex: u32 = 0,
    first_instance: u32 = 0,
};

pub const DispatchArguments = extern struct {
    x: u32,
    y: u32 = 1,
    z: u32 = 1,
};

pub const Formats = extern struct {
    count: u32 = 0,
    ptr: ?[*]const Format = null,

    pub fn fromSlice(slice: []const Format) Formats {
        return .{ .count = @intCast(slice.len), .ptr = slice.ptr };
    }
};

pub const TextureDesc = extern struct {
    type: TextureDimension = .@"2d",
    extent: Extent3D,
    mip_count: u32 = 1,
    layer_count: u32 = 1,
    /// 1, 2, 4 or 8. Multisampled textures must be 2D with a single mip, can't have storage usage and can't be copied.
    sample_count: u32 = 1,
    format: Format,
    usage: TextureUsage = .{},
    /// Additional formats this texture may be viewed as (must be format-compatible).
    /// listing formats can disable lossless compression.
    /// Only read during creation.
    view_formats: Formats = .{},
};

pub const TextureViewDesc = extern struct {
    /// `.none` selects the format of the texture. Otherwise must be the format of the texture or one of its view formats.
    /// Depth-stencil textures are viewed through their depth aspect, unless the format is `.stencil8` which selects the stencil aspect (doesn't need to be listed in view formats).
    format: Format = .none,
    base_mip: u32 = 0,
    /// 0 selects all mips from base_mip.
    mip_count: u32 = 0,
    base_layer: u32 = 0,
    /// 0 selects all layers from base_layer.
    layer_count: u32 = 0,
};

pub const TextureCopyDesc = extern struct {
    /// `.none` selects the format of the texture. Otherwise must be the format of the texture or `.stencil8`.
    /// Depth-stencil textures copy their depth aspect, unless the format is `.stencil8` which copies the stencil aspect.
    format: Format = .none,
    mip: u32 = 0,
    base_layer: u32 = 0,
    /// 0 selects all layers from base_layer.
    layer_count: u32 = 0,
    /// Must not be negative. Must be a multiple of the format's block extent times the queue's texture copy granularity.
    offset: Offset3D = .{},
    /// Zero components select the rest of the mip. Must be a multiple of the format's block extent times the queue's texture copy granularity unless it reaches the edge of the mip.
    extent: Extent3D = .{ .width = 0, .height = 0, .depth = 0 },
    /// Distance between rows of blocks in memory, 0 is tightly packed. Must be a multiple of the format's block size.
    row_pitch_bytes: usize = 0,
    /// Distance between depth slices or layers in memory, 0 is tightly packed. Must be a multiple of the row pitch.
    slice_pitch_bytes: usize = 0,
};

pub const Descriptor = extern struct {
    data: [descriptor_size_max]u8,
};

pub const BlendDesc = extern struct {
    color_op: BlendOp = .add,
    src_color_factor: BlendFactor = .one,
    dst_color_factor: BlendFactor = .zero,
    alpha_op: BlendOp = .add,
    src_alpha_factor: BlendFactor = .one,
    dst_alpha_factor: BlendFactor = .zero,
};

pub const ColorTarget = extern struct {
    format: Format,
    write_mask: ColorWriteMask = .all,
    blend: ?*const BlendDesc = null,
};

pub const ColorTargets = extern struct {
    count: u32 = 0,
    ptr: ?[*]const ColorTarget = null,

    pub fn fromSlice(slice: []const ColorTarget) ColorTargets {
        return .{ .count = @intCast(slice.len), .ptr = slice.ptr };
    }
};

pub const GraphicsPipelineDesc = extern struct {
    topology: Topology = .triangle_list,
    cull: Cull = .none,
    alpha_to_coverage: bool = false,
    /// Must match the sample count of every attachment of the render pass.
    sample_count: u32 = 1,
    /// `.none` for no depth attachment.
    depth_format: Format = .none,
    /// `.none` for no stencil attachment.
    stencil_format: Format = .none,
    color_targets: ColorTargets = .{},
};

pub const StencilDesc = extern struct {
    @"test": CompareOp = .always,
    fail_op: StencilOp = .keep,
    pass_op: StencilOp = .keep,
    depth_fail_op: StencilOp = .keep,
    reference: u8 = 0,
};

pub const DepthStencilDesc = extern struct {
    depth_mode: DepthFlags = .{},
    depth_test: CompareOp = .always,
    depth_bias: f32 = 0,
    depth_bias_slope_factor: f32 = 0,
    depth_bias_clamp: f32 = 0,
    stencil_read_mask: u8 = 255,
    stencil_write_mask: u8 = 255,
    stencil_front: StencilDesc = .{},
    stencil_back: StencilDesc = .{},
};

test {
    _ = @import("check.zig");
}
