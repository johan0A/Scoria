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
    pub const createTexture = functions.createTexture;
    pub const createComputePipeline = functions.createComputePipeline;
    pub const createGraphicsPipeline = functions.createGraphicsPipeline;
    pub const createDepthStencilState = functions.createDepthStencilState;
};

pub const Queue = opaque {
    pub const startCommandRecording = functions.startCommandRecording;
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

pub const Format = enum(u32) {
    none = 0,
    r8_unorm = 1,
    r8_snorm = 2,
    r8_uint = 3,
    r8_sint = 4,
    r16_unorm = 5,
    r16_snorm = 6,
    r16_uint = 7,
    r16_sint = 8,
    r16_float = 9,
    rg8_unorm = 10,
    rg8_snorm = 11,
    rg8_uint = 12,
    rg8_sint = 13,
    r32_float = 14,
    r32_uint = 15,
    r32_sint = 16,
    rg16_unorm = 17,
    rg16_snorm = 18,
    rg16_uint = 19,
    rg16_sint = 20,
    rg16_float = 21,
    rgba8_unorm = 22,
    rgba8_unorm_srgb = 23,
    rgba8_snorm = 24,
    rgba8_uint = 25,
    rgba8_sint = 26,
    bgra8_unorm = 27,
    bgra8_unorm_srgb = 28,
    rgb10a2_uint = 29,
    rgb10a2_unorm = 30,
    rg11b10_ufloat = 31,
    rgb9e5_ufloat = 32,
    rg32_float = 33,
    rg32_uint = 34,
    rg32_sint = 35,
    rgba16_unorm = 36,
    rgba16_snorm = 37,
    rgba16_uint = 38,
    rgba16_sint = 39,
    rgba16_float = 40,
    rgba32_float = 41,
    rgba32_uint = 42,
    rgba32_sint = 43,
    stencil8 = 44,
    depth16_unorm = 45,
    depth24_plus = 46,
    depth24_plus_stencil8 = 47,
    depth32_float = 48,
    depth32_float_stencil8 = 49,
    bc1rgba_unorm = 50,
    bc1rgba_unorm_srgb = 51,
    bc2rgba_unorm = 52,
    bc2rgba_unorm_srgb = 53,
    bc3rgba_unorm = 54,
    bc3rgba_unorm_srgb = 55,
    bc4r_unorm = 56,
    bc4r_snorm = 57,
    bc5rg_unorm = 58,
    bc5rg_snorm = 59,
    bc6hrgb_ufloat = 60,
    bc6hrgb_float = 61,
    bc7rgba_unorm = 62,
    bc7rgba_unorm_srgb = 63,
    etc2rgb8_unorm = 64,
    etc2rgb8_unorm_srgb = 65,
    etc2rgb8a1_unorm = 66,
    etc2rgb8a1_unorm_srgb = 67,
    etc2rgba8_unorm = 68,
    etc2rgba8_unorm_srgb = 69,
    eacr11_unorm = 70,
    eacr11_snorm = 71,
    eacrg11_unorm = 72,
    eacrg11_snorm = 73,
    astc4x4_unorm = 74,
    astc4x4_unorm_srgb = 75,
    astc5x4_unorm = 76,
    astc5x4_unorm_srgb = 77,
    astc5x5_unorm = 78,
    astc5x5_unorm_srgb = 79,
    astc6x5_unorm = 80,
    astc6x5_unorm_srgb = 81,
    astc6x6_unorm = 82,
    astc6x6_unorm_srgb = 83,
    astc8x5_unorm = 84,
    astc8x5_unorm_srgb = 85,
    astc8x6_unorm = 86,
    astc8x6_unorm_srgb = 87,
    astc8x8_unorm = 88,
    astc8x8_unorm_srgb = 89,
    astc10x5_unorm = 90,
    astc10x5_unorm_srgb = 91,
    astc10x6_unorm = 92,
    astc10x6_unorm_srgb = 93,
    astc10x8_unorm = 94,
    astc10x8_unorm_srgb = 95,
    astc10x10_unorm = 96,
    astc10x10_unorm_srgb = 97,
    astc12x10_unorm = 98,
    astc12x10_unorm_srgb = 99,
    astc12x12_unorm = 100,
    astc12x12_unorm_srgb = 101,
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
};

pub const RenderPassDesc = extern struct {
    depth_attachment: DepthAttachment = .{},
    stencil_attachment: StencilAttachment = .{},
    color_attachment_count: u32 = 0,
    color_attachments: ?[*]const ColorAttachment = null,
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

pub const TextureDesc = extern struct {
    type: TextureDimension = .@"2d",
    extent: Extent3D,
    mip_count: u32 = 1,
    layer_count: u32 = 1,
    format: Format,
    usage: TextureUsage = .{},
};

pub const TextureViewDesc = extern struct {
    /// `.none` selects the format of the texture.
    format: Format = .none,
    base_mip: u32 = 0,
    /// 0 selects all mips from base_mip.
    mip_count: u32 = 0,
    base_layer: u32 = 0,
    /// 0 selects all layers from base_layer.
    layer_count: u32 = 0,
};

pub const TextureCopyDesc = extern struct {
    mip: u32 = 0,
    base_layer: u32 = 0,
    /// 0 selects all layers from base_layer.
    layer_count: u32 = 0,
    /// Must not be negative. Must be a multiple of the format's block extent.
    offset: Offset3D = .{},
    /// Zero components select the rest of the mip. Must be a multiple of the format's block extent unless it reaches the edge of the mip.
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

pub const GraphicsPipelineDesc = extern struct {
    topology: Topology = .triangle_list,
    cull: Cull = .none,
    alpha_to_coverage: bool = false,
    sample_count: u32 = 1,
    /// `.none` for no depth attachment.
    depth_format: Format = .none,
    /// `.none` for no stencil attachment.
    stencil_format: Format = .none,
    color_target_count: u32 = 0,
    color_targets: ?[*]const ColorTarget = null,
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
