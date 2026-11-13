// Generated file, do not edit.
// version: 0.1.0

const std = @import("std");
const target = @import("builtin").target;

pub const @"callconv": std.lang.CallingConvention = switch (target.os.tag) {
    .windows => if (target.cpu.arch == .x86) .{ .x86_stdcall = .{} } else .c,
    else => .c,
};

pub const descriptor_size_max: usize = 64;
pub const adapter_name_capacity_bytes: usize = 256;

pub const DeviceAddress = u64;

pub const Instance = opaque {};
pub const Surface = opaque {};
pub const Adapter = opaque {};
pub const Device = opaque {};
pub const Queue = opaque {};
pub const Timeline = opaque {};
pub const Swapchain = opaque {};
pub const CommandPool = opaque {};
pub const CommandBuffer = opaque {};
pub const Texture = opaque {};
pub const Pipeline = opaque {};
pub const DepthStencilState = opaque {};

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
/// - SC_FORMAT_R8_UNORM to SC_FORMAT_RG11B10_UFLOAT: S F R B M W
/// - SC_FORMAT_RGBA8_UNORM_SRGB to SC_FORMAT_BGRA8_UNORM_SRGB: S F R B M
/// - SC_FORMAT_R8_SNORM to SC_FORMAT_RGBA16_SNORM: S F W
/// - SC_FORMAT_RGB9E5_UFLOAT: S F
/// - SC_FORMAT_R32_FLOAT to SC_FORMAT_RGBA32_FLOAT: S R M W, F B with SC_FORMAT_FEATURES_FLOAT32_FILTERING_BLENDING_BIT
/// - SC_FORMAT_R8_UINT to SC_FORMAT_RGB10A2_UINT: S R M W
/// - SC_FORMAT_DEPTH16_UNORM to SC_FORMAT_STENCIL8: S R M, the depth aspect also supports comparison sampling
/// - SC_FORMAT_BC1_UNORM to SC_FORMAT_BC7_UNORM_SRGB: S F, 4x4 blocks, requires SC_FORMAT_FEATURES_BC_BIT
/// - SC_FORMAT_ASTC_4X4_UNORM to SC_FORMAT_ASTC_12X12_UNORM_SRGB: S F, requires SC_FORMAT_FEATURES_ASTC_BIT
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
    /// Also selects the stencil aspect of SC_FORMAT_DEPTH32_FLOAT_STENCIL8 in views and copies.
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

/// Format capabilities beyond the guarantees of ScFormat. At least one of BC and ASTC is always available.
pub const FormatFeatures = packed struct(u32) {
    /// SC_FORMAT_R32_FLOAT to SC_FORMAT_RGBA32_FLOAT support linear filtering and blending.
    float32_filtering_blending: bool = false,
    /// SC_FORMAT_BC1_UNORM to SC_FORMAT_BC7_UNORM_SRGB are available.
    bc: bool = false,
    /// SC_FORMAT_ASTC_4X4_UNORM to SC_FORMAT_ASTC_12X12_UNORM_SRGB are available.
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
    alignment: usize,
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
    device: DeviceAddress,
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
    /// SC_FORMAT_NONE selects the format of the texture. Otherwise must be the format of the texture or one of its view formats.
    /// Depth-stencil textures are viewed through their depth aspect, unless the format is SC_FORMAT_STENCIL8 which selects the stencil aspect (it doesn't need to be listed in view formats).
    format: Format = .none,
    base_mip: u32 = 0,
    /// 0 selects all mips from base_mip.
    mip_count: u32 = 0,
    base_layer: u32 = 0,
    /// 0 selects all layers from base_layer.
    layer_count: u32 = 0,
};

pub const TextureCopyDesc = extern struct {
    /// SC_FORMAT_NONE selects the format of the texture. Otherwise must be the format of the texture or SC_FORMAT_STENCIL8.
    /// Depth-stencil textures copy their depth aspect, unless the format is SC_FORMAT_STENCIL8 which copies the stencil aspect (one byte per texel).
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
};

pub const GraphicsPipelineDesc = extern struct {
    topology: Topology = .triangle_list,
    cull: Cull = .none,
    alpha_to_coverage: bool = false,
    /// Must match the sample count of every attachment of the render pass.
    sample_count: u32 = 1,
    /// SC_FORMAT_NONE for no depth attachment.
    depth_format: Format = .none,
    /// SC_FORMAT_NONE for no stencil attachment.
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

pub fn createInstance(
    allocator: ?*HostAllocator,
    getSymbol: Symbol,
) *Instance {
    internal.loadGlobals(getSymbol);
    const f = internal.create_instance.?;
    const instance = f(
        allocator,
    );
    internal.loadSlots(instance);
    return instance;
}

pub fn destroyInstance(
    instance: *Instance,
) void {
    const f = internal.destroy_instance.?;
    return f(
        instance,
    );
}

pub fn enumerateAdapters(
    instance: *Instance,
    adapters_capacity: usize,
    adapters: ?[*]*Adapter,
    adapter_count: *usize,
) void {
    const f = internal.enumerate_adapters.?;
    return f(
        instance,
        adapters_capacity,
        adapters,
        adapter_count,
    );
}

pub fn createDevice(
    instance: *Instance,
    adapter: *Adapter,
) *Device {
    const f = internal.create_device.?;
    return f(
        instance,
        adapter,
    );
}

pub fn destroyDevice(
    device: *Device,
) void {
    const f = internal.destroy_device.?;
    return f(
        device,
    );
}

pub fn adapterInfo(
    instance: *Instance,
    adapter: *Adapter,
) AdapterInfo {
    const f: *const fn (
        instance: *Instance,
        adapter: *Adapter,
    ) callconv(@"callconv") AdapterInfo = @ptrCast(internal.table(instance)[internal.slots.adapter_info]);
    return f(
        instance,
        adapter,
    );
}

pub fn createSurfaceWin32(
    device: *Device,
    desc: SurfaceWin32Desc,
) *Surface {
    const f: *const fn (
        device: *Device,
        desc: SurfaceWin32Desc,
    ) callconv(@"callconv") *Surface = @ptrCast(internal.table(device)[internal.slots.create_surface_win32]);
    return f(
        device,
        desc,
    );
}

pub fn createSurfaceXlib(
    device: *Device,
    desc: SurfaceXlibDesc,
) *Surface {
    const f: *const fn (
        device: *Device,
        desc: SurfaceXlibDesc,
    ) callconv(@"callconv") *Surface = @ptrCast(internal.table(device)[internal.slots.create_surface_xlib]);
    return f(
        device,
        desc,
    );
}

pub fn destroySurface(
    surface: *Surface,
) void {
    const f: *const fn (
        surface: *Surface,
    ) callconv(@"callconv") void = @ptrCast(internal.table(surface)[internal.slots.destroy_surface]);
    return f(
        surface,
    );
}

pub fn surfaceSupportedUsage(
    surface: *Surface,
) TextureUsage {
    const f: *const fn (
        surface: *Surface,
    ) callconv(@"callconv") TextureUsage = @ptrCast(internal.table(surface)[internal.slots.surface_supported_usage]);
    return f(
        surface,
    );
}

pub fn surfaceSupportedFormats(
    surface: *Surface,
    color_space: ColorSpace,
    formats_capacity: usize,
    formats: ?[*]Format,
    format_count: *usize,
) void {
    const f: *const fn (
        surface: *Surface,
        color_space: ColorSpace,
        formats_capacity: usize,
        formats: ?[*]Format,
        format_count: *usize,
    ) callconv(@"callconv") void = @ptrCast(internal.table(surface)[internal.slots.surface_supported_formats]);
    return f(
        surface,
        color_space,
        formats_capacity,
        formats,
        format_count,
    );
}

pub fn surfacePresentModes(
    surface: *Surface,
    present_modes_capacity: usize,
    present_modes: ?[*]PresentMode,
    present_mode_count: *usize,
) void {
    const f: *const fn (
        surface: *Surface,
        present_modes_capacity: usize,
        present_modes: ?[*]PresentMode,
        present_mode_count: *usize,
    ) callconv(@"callconv") void = @ptrCast(internal.table(surface)[internal.slots.surface_present_modes]);
    return f(
        surface,
        present_modes_capacity,
        present_modes,
        present_mode_count,
    );
}

pub fn hostFromDevicePointer(
    device: *Device,
    address: DeviceAddress,
) *anyopaque {
    const f: *const fn (
        device: *Device,
        address: DeviceAddress,
    ) callconv(@"callconv") *anyopaque = @ptrCast(internal.table(device)[internal.slots.host_from_device_pointer]);
    return f(
        device,
        address,
    );
}

pub fn alloc(
    device: *Device,
    size: usize,
    alignment: usize,
    memory: MemoryKind,
    device_mapping: *HostDeviceAddress,
) Result {
    const f: *const fn (
        device: *Device,
        size: usize,
        alignment: usize,
        memory: MemoryKind,
        device_mapping: *HostDeviceAddress,
    ) callconv(@"callconv") Result = @ptrCast(internal.table(device)[internal.slots.alloc]);
    return f(
        device,
        size,
        alignment,
        memory,
        device_mapping,
    );
}

pub fn free(
    device: *Device,
    address: DeviceAddress,
) void {
    const f: *const fn (
        device: *Device,
        address: DeviceAddress,
    ) callconv(@"callconv") void = @ptrCast(internal.table(device)[internal.slots.free]);
    return f(
        device,
        address,
    );
}

pub fn descriptorSizeAndHeapAlign(
    device: *Device,
) SizeAlign {
    const f: *const fn (
        device: *Device,
    ) callconv(@"callconv") SizeAlign = @ptrCast(internal.table(device)[internal.slots.descriptor_size_and_heap_align]);
    return f(
        device,
    );
}

pub fn storeDescriptor(
    device: *Device,
    descriptor: *const Descriptor,
    descriptor_heap: [*]u8,
    index: usize,
) void {
    const f: *const fn (
        device: *Device,
        descriptor: *const Descriptor,
        descriptor_heap: [*]u8,
        index: usize,
    ) callconv(@"callconv") void = @ptrCast(internal.table(device)[internal.slots.store_descriptor]);
    return f(
        device,
        descriptor,
        descriptor_heap,
        index,
    );
}

pub fn getQueue(
    device: *Device,
    queue_kind: QueueKind,
) *Queue {
    const f: *const fn (
        device: *Device,
        queue_kind: QueueKind,
    ) callconv(@"callconv") *Queue = @ptrCast(internal.table(device)[internal.slots.get_queue]);
    return f(
        device,
        queue_kind,
    );
}

/// Texture copies recorded for this queue must have an offset that is a multiple of the granularity times the format's block extent, and an extent that is a multiple of it unless it reaches the edge of the mip. Never 0, and always (1, 1, 1) for graphics and compute queues.
pub fn textureCopyGranularity(
    queue: *Queue,
) Extent3D {
    const f: *const fn (
        queue: *Queue,
    ) callconv(@"callconv") Extent3D = @ptrCast(internal.table(queue)[internal.slots.texture_copy_granularity]);
    return f(
        queue,
    );
}

pub fn createCommandPool(
    queue: *Queue,
    command_pool: **CommandPool,
) Result {
    const f: *const fn (
        queue: *Queue,
        command_pool: **CommandPool,
    ) callconv(@"callconv") Result = @ptrCast(internal.table(queue)[internal.slots.create_command_pool]);
    return f(
        queue,
        command_pool,
    );
}

/// Submitted command buffers of the pool must have completed.
pub fn destroyCommandPool(
    command_pool: *CommandPool,
) void {
    const f: *const fn (
        command_pool: *CommandPool,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_pool)[internal.slots.destroy_command_pool]);
    return f(
        command_pool,
    );
}

/// Invalidates every command buffer of the pool and recycles their memory. Submitted command buffers of the pool must have completed.
pub fn resetCommandPool(
    command_pool: *CommandPool,
) Result {
    const f: *const fn (
        command_pool: *CommandPool,
    ) callconv(@"callconv") Result = @ptrCast(internal.table(command_pool)[internal.slots.reset_command_pool]);
    return f(
        command_pool,
    );
}

/// The command buffer stays valid until its pool is reset or destroyed, it can be submitted once to the queue of the pool.
pub fn startCommandRecording(
    command_pool: *CommandPool,
    command_buffer: **CommandBuffer,
) Result {
    const f: *const fn (
        command_pool: *CommandPool,
        command_buffer: **CommandBuffer,
    ) callconv(@"callconv") Result = @ptrCast(internal.table(command_pool)[internal.slots.start_command_recording]);
    return f(
        command_pool,
        command_buffer,
    );
}

pub fn submit(
    queue: *Queue,
    command_buffer_count: usize,
    command_buffers: [*]const *CommandBuffer,
    wait_count: usize,
    waits: [*]const TimelinePoint,
) Result {
    const f: *const fn (
        queue: *Queue,
        command_buffer_count: usize,
        command_buffers: [*]const *CommandBuffer,
        wait_count: usize,
        waits: [*]const TimelinePoint,
    ) callconv(@"callconv") Result = @ptrCast(internal.table(queue)[internal.slots.submit]);
    return f(
        queue,
        command_buffer_count,
        command_buffers,
        wait_count,
        waits,
    );
}

pub fn submitAndSignal(
    queue: *Queue,
    command_buffer_count: usize,
    command_buffers: [*]const *CommandBuffer,
    wait_count: usize,
    waits: [*]const TimelinePoint,
    signal: TimelinePoint,
) Result {
    const f: *const fn (
        queue: *Queue,
        command_buffer_count: usize,
        command_buffers: [*]const *CommandBuffer,
        wait_count: usize,
        waits: [*]const TimelinePoint,
        signal: TimelinePoint,
    ) callconv(@"callconv") Result = @ptrCast(internal.table(queue)[internal.slots.submit_and_signal]);
    return f(
        queue,
        command_buffer_count,
        command_buffers,
        wait_count,
        waits,
        signal,
    );
}

pub fn createTimeline(
    device: *Device,
    initial_value: u64,
    timeline: **Timeline,
) Result {
    const f: *const fn (
        device: *Device,
        initial_value: u64,
        timeline: **Timeline,
    ) callconv(@"callconv") Result = @ptrCast(internal.table(device)[internal.slots.create_timeline]);
    return f(
        device,
        initial_value,
        timeline,
    );
}

pub fn destroyTimeline(
    timeline: *Timeline,
) void {
    const f: *const fn (
        timeline: *Timeline,
    ) callconv(@"callconv") void = @ptrCast(internal.table(timeline)[internal.slots.destroy_timeline]);
    return f(
        timeline,
    );
}

pub fn waitTimelinePoint(
    point: TimelinePoint,
) Result {
    const f: *const fn (
        point: TimelinePoint,
    ) callconv(@"callconv") Result = @ptrCast(internal.table(point.timeline)[internal.slots.wait_timeline_point]);
    return f(
        point,
    );
}

pub fn createSwapchain(
    queue: *Queue,
    surface: *Surface,
    desc: SwapchainDesc,
    swapchain: **Swapchain,
) Result {
    const f: *const fn (
        queue: *Queue,
        surface: *Surface,
        desc: SwapchainDesc,
        swapchain: **Swapchain,
    ) callconv(@"callconv") Result = @ptrCast(internal.table(queue)[internal.slots.create_swapchain]);
    return f(
        queue,
        surface,
        desc,
        swapchain,
    );
}

pub fn destroySwapchain(
    swapchain: *Swapchain,
) void {
    const f: *const fn (
        swapchain: *Swapchain,
    ) callconv(@"callconv") void = @ptrCast(internal.table(swapchain)[internal.slots.destroy_swapchain]);
    return f(
        swapchain,
    );
}

pub fn acquireBackBuffer(
    swapchain: *Swapchain,
    extent: Extent2D,
    back_buffer: *BackBuffer,
) Result {
    const f: *const fn (
        swapchain: *Swapchain,
        extent: Extent2D,
        back_buffer: *BackBuffer,
    ) callconv(@"callconv") Result = @ptrCast(internal.table(swapchain)[internal.slots.acquire_back_buffer]);
    return f(
        swapchain,
        extent,
        back_buffer,
    );
}

pub fn present(
    swapchain: *Swapchain,
) Result {
    const f: *const fn (
        swapchain: *Swapchain,
    ) callconv(@"callconv") Result = @ptrCast(internal.table(swapchain)[internal.slots.present]);
    return f(
        swapchain,
    );
}

pub fn setActiveTextureHeap(
    command_buffer: *CommandBuffer,
    heap_address: DeviceAddress,
) void {
    const f: *const fn (
        command_buffer: *CommandBuffer,
        heap_address: DeviceAddress,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.set_active_texture_heap]);
    return f(
        command_buffer,
        heap_address,
    );
}

pub fn setDepthStencilState(
    command_buffer: *CommandBuffer,
    depth_stencil_state: *DepthStencilState,
) void {
    const f: *const fn (
        command_buffer: *CommandBuffer,
        depth_stencil_state: *DepthStencilState,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.set_depth_stencil_state]);
    return f(
        command_buffer,
        depth_stencil_state,
    );
}

pub fn setPipeline(
    command_buffer: *CommandBuffer,
    pipeline: *Pipeline,
) void {
    const f: *const fn (
        command_buffer: *CommandBuffer,
        pipeline: *Pipeline,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.set_pipeline]);
    return f(
        command_buffer,
        pipeline,
    );
}

pub fn dispatch(
    command_buffer: *CommandBuffer,
    data: DeviceAddress,
    x: u32,
    y: u32,
    z: u32,
) void {
    const f: *const fn (
        command_buffer: *CommandBuffer,
        data: DeviceAddress,
        x: u32,
        y: u32,
        z: u32,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.dispatch]);
    return f(
        command_buffer,
        data,
        x,
        y,
        z,
    );
}

pub fn dispatchIndirect(
    command_buffer: *CommandBuffer,
    data: DeviceAddress,
    arguments: DeviceAddress,
) void {
    const f: *const fn (
        command_buffer: *CommandBuffer,
        data: DeviceAddress,
        arguments: DeviceAddress,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.dispatch_indirect]);
    return f(
        command_buffer,
        data,
        arguments,
    );
}

pub fn barrier(
    command_buffer: *CommandBuffer,
    before: Stage,
    after: Stage,
    hazard: Hazard,
) void {
    const f: *const fn (
        command_buffer: *CommandBuffer,
        before: Stage,
        after: Stage,
        hazard: Hazard,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.barrier]);
    return f(
        command_buffer,
        before,
        after,
        hazard,
    );
}

/// 256 bytes is a typical optimal alignment for destination
pub fn copyTextureToMemory(
    command_buffer: *CommandBuffer,
    source_texture: *Texture,
    destination: DeviceAddress,
    size: usize,
    desc: TextureCopyDesc,
) void {
    const f: *const fn (
        command_buffer: *CommandBuffer,
        source_texture: *Texture,
        destination: DeviceAddress,
        size: usize,
        desc: TextureCopyDesc,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.copy_texture_to_memory]);
    return f(
        command_buffer,
        source_texture,
        destination,
        size,
        desc,
    );
}

pub fn copyMemoryToTexture(
    command_buffer: *CommandBuffer,
    source: DeviceAddress,
    size: usize,
    destination_texture: *Texture,
    desc: TextureCopyDesc,
) void {
    const f: *const fn (
        command_buffer: *CommandBuffer,
        source: DeviceAddress,
        size: usize,
        destination_texture: *Texture,
        desc: TextureCopyDesc,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.copy_memory_to_texture]);
    return f(
        command_buffer,
        source,
        size,
        destination_texture,
        desc,
    );
}

pub fn copyMemory(
    command_buffer: *CommandBuffer,
    source: DeviceAddress,
    destination: DeviceAddress,
    size: usize,
) void {
    const f: *const fn (
        command_buffer: *CommandBuffer,
        source: DeviceAddress,
        destination: DeviceAddress,
        size: usize,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.copy_memory]);
    return f(
        command_buffer,
        source,
        destination,
        size,
    );
}

pub fn beginRenderPass(
    command_buffer: *CommandBuffer,
    desc: RenderPassDesc,
) void {
    const f: *const fn (
        command_buffer: *CommandBuffer,
        desc: RenderPassDesc,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.begin_render_pass]);
    return f(
        command_buffer,
        desc,
    );
}

pub fn endRenderPass(
    command_buffer: *CommandBuffer,
) void {
    const f: *const fn (
        command_buffer: *CommandBuffer,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.end_render_pass]);
    return f(
        command_buffer,
    );
}

/// Only valid inside a render pass. Beginning a render pass resets the scissor to the full render target.
pub fn setScissor(
    command_buffer: *CommandBuffer,
    rect: Rect2D,
) void {
    const f: *const fn (
        command_buffer: *CommandBuffer,
        rect: Rect2D,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.set_scissor]);
    return f(
        command_buffer,
        rect,
    );
}

/// Only valid inside a render pass. Beginning a render pass resets the viewport to the full render target with a [0, 1] depth range.
pub fn setViewport(
    command_buffer: *CommandBuffer,
    viewport: Viewport,
) void {
    const f: *const fn (
        command_buffer: *CommandBuffer,
        viewport: Viewport,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.set_viewport]);
    return f(
        command_buffer,
        viewport,
    );
}

pub fn draw(
    command_buffer: *CommandBuffer,
    vertex_data: DeviceAddress,
    pixel_data: DeviceAddress,
    vertex_count: u32,
    instance_count: u32,
) void {
    const f: *const fn (
        command_buffer: *CommandBuffer,
        vertex_data: DeviceAddress,
        pixel_data: DeviceAddress,
        vertex_count: u32,
        instance_count: u32,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.draw]);
    return f(
        command_buffer,
        vertex_data,
        pixel_data,
        vertex_count,
        instance_count,
    );
}

pub fn drawIndexed(
    command_buffer: *CommandBuffer,
    vertex_data: DeviceAddress,
    pixel_data: DeviceAddress,
    index_type: IndexType,
    indices: DeviceAddress,
    index_count: u32,
) void {
    const f: *const fn (
        command_buffer: *CommandBuffer,
        vertex_data: DeviceAddress,
        pixel_data: DeviceAddress,
        index_type: IndexType,
        indices: DeviceAddress,
        index_count: u32,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.draw_indexed]);
    return f(
        command_buffer,
        vertex_data,
        pixel_data,
        index_type,
        indices,
        index_count,
    );
}

pub fn drawIndexedInstanced(
    command_buffer: *CommandBuffer,
    vertex_data: DeviceAddress,
    pixel_data: DeviceAddress,
    index_type: IndexType,
    indices: DeviceAddress,
    index_count: u32,
    instance_count: u32,
) void {
    const f: *const fn (
        command_buffer: *CommandBuffer,
        vertex_data: DeviceAddress,
        pixel_data: DeviceAddress,
        index_type: IndexType,
        indices: DeviceAddress,
        index_count: u32,
        instance_count: u32,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.draw_indexed_instanced]);
    return f(
        command_buffer,
        vertex_data,
        pixel_data,
        index_type,
        indices,
        index_count,
        instance_count,
    );
}

/// Use SV_DrawIndex in the shader to tell the draws apart.
pub fn drawIndexedInstancedIndirect(
    command_buffer: *CommandBuffer,
    vertex_data: DeviceAddress,
    pixel_data: DeviceAddress,
    index_type: IndexType,
    indices: DeviceAddress,
    arguments: DeviceAddress,
    draw_count: u32,
) void {
    const f: *const fn (
        command_buffer: *CommandBuffer,
        vertex_data: DeviceAddress,
        pixel_data: DeviceAddress,
        index_type: IndexType,
        indices: DeviceAddress,
        arguments: DeviceAddress,
        draw_count: u32,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.draw_indexed_instanced_indirect]);
    return f(
        command_buffer,
        vertex_data,
        pixel_data,
        index_type,
        indices,
        arguments,
        draw_count,
    );
}

/// Use SV_DrawIndex in the shader to tell the draws apart.
pub fn drawIndirect(
    command_buffer: *CommandBuffer,
    vertex_data: DeviceAddress,
    pixel_data: DeviceAddress,
    arguments: DeviceAddress,
    draw_count: u32,
) void {
    const f: *const fn (
        command_buffer: *CommandBuffer,
        vertex_data: DeviceAddress,
        pixel_data: DeviceAddress,
        arguments: DeviceAddress,
        draw_count: u32,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.draw_indirect]);
    return f(
        command_buffer,
        vertex_data,
        pixel_data,
        arguments,
        draw_count,
    );
}

pub fn textureSizeAlign(
    device: *Device,
    desc: TextureDesc,
) SizeAlign {
    const f: *const fn (
        device: *Device,
        desc: TextureDesc,
    ) callconv(@"callconv") SizeAlign = @ptrCast(internal.table(device)[internal.slots.texture_size_align]);
    return f(
        device,
        desc,
    );
}

/// Highest sample count the texture can be created with, every power of two below it is supported too. At most 8, and 0 when the texture can't be created at all. At least 4 for attachments with a non-integer format.
pub fn textureSampleCountMax(
    device: *Device,
    desc: TextureDesc,
) u32 {
    const f: *const fn (
        device: *Device,
        desc: TextureDesc,
    ) callconv(@"callconv") u32 = @ptrCast(internal.table(device)[internal.slots.texture_sample_count_max]);
    return f(
        device,
        desc,
    );
}

pub fn createTexture(
    device: *Device,
    desc: TextureDesc,
    data: DeviceAddress,
    texture: **Texture,
) Result {
    const f: *const fn (
        device: *Device,
        desc: TextureDesc,
        data: DeviceAddress,
        texture: **Texture,
    ) callconv(@"callconv") Result = @ptrCast(internal.table(device)[internal.slots.create_texture]);
    return f(
        device,
        desc,
        data,
        texture,
    );
}

pub fn destroyTexture(
    texture: *Texture,
) void {
    const f: *const fn (
        texture: *Texture,
    ) callconv(@"callconv") void = @ptrCast(internal.table(texture)[internal.slots.destroy_texture]);
    return f(
        texture,
    );
}

pub fn textureStorageDescriptor(
    texture: *Texture,
    desc: TextureViewDesc,
    descriptor: *Descriptor,
) Result {
    const f: *const fn (
        texture: *Texture,
        desc: TextureViewDesc,
        descriptor: *Descriptor,
    ) callconv(@"callconv") Result = @ptrCast(internal.table(texture)[internal.slots.texture_storage_descriptor]);
    return f(
        texture,
        desc,
        descriptor,
    );
}

pub fn textureViewDescriptor(
    texture: *Texture,
    desc: TextureViewDesc,
    descriptor: *Descriptor,
) Result {
    const f: *const fn (
        texture: *Texture,
        desc: TextureViewDesc,
        descriptor: *Descriptor,
    ) callconv(@"callconv") Result = @ptrCast(internal.table(texture)[internal.slots.texture_view_descriptor]);
    return f(
        texture,
        desc,
        descriptor,
    );
}

pub fn createComputePipeline(
    device: *Device,
    ir_size: usize,
    ir: [*]const u8,
    pipeline: **Pipeline,
) Result {
    const f: *const fn (
        device: *Device,
        ir_size: usize,
        ir: [*]const u8,
        pipeline: **Pipeline,
    ) callconv(@"callconv") Result = @ptrCast(internal.table(device)[internal.slots.create_compute_pipeline]);
    return f(
        device,
        ir_size,
        ir,
        pipeline,
    );
}

pub fn createGraphicsPipeline(
    device: *Device,
    vertex_ir_size: usize,
    vertex_ir: [*]const u8,
    pixel_ir_size: usize,
    pixel_ir: [*]const u8,
    desc: GraphicsPipelineDesc,
    pipeline: **Pipeline,
) Result {
    const f: *const fn (
        device: *Device,
        vertex_ir_size: usize,
        vertex_ir: [*]const u8,
        pixel_ir_size: usize,
        pixel_ir: [*]const u8,
        desc: GraphicsPipelineDesc,
        pipeline: **Pipeline,
    ) callconv(@"callconv") Result = @ptrCast(internal.table(device)[internal.slots.create_graphics_pipeline]);
    return f(
        device,
        vertex_ir_size,
        vertex_ir,
        pixel_ir_size,
        pixel_ir,
        desc,
        pipeline,
    );
}

pub fn destroyPipeline(
    pipeline: *Pipeline,
) void {
    const f: *const fn (
        pipeline: *Pipeline,
    ) callconv(@"callconv") void = @ptrCast(internal.table(pipeline)[internal.slots.destroy_pipeline]);
    return f(
        pipeline,
    );
}

pub fn createDepthStencilState(
    device: *Device,
    desc: DepthStencilDesc,
    depth_stencil_state: **DepthStencilState,
) Result {
    const f: *const fn (
        device: *Device,
        desc: DepthStencilDesc,
        depth_stencil_state: **DepthStencilState,
    ) callconv(@"callconv") Result = @ptrCast(internal.table(device)[internal.slots.create_depth_stencil_state]);
    return f(
        device,
        desc,
        depth_stencil_state,
    );
}

pub fn destroyDepthStencilState(
    depth_stencil_state: *DepthStencilState,
) void {
    const f: *const fn (
        depth_stencil_state: *DepthStencilState,
    ) callconv(@"callconv") void = @ptrCast(internal.table(depth_stencil_state)[internal.slots.destroy_depth_stencil_state]);
    return f(
        depth_stencil_state,
    );
}

const internal = struct {
    inline fn table(handle: *const anyopaque) [*]const *const anyopaque {
        return @as(*const [*]const *const anyopaque, @ptrCast(@alignCast(handle))).*;
    }

    var create_instance: ?*const fn (
        allocator: ?*HostAllocator,
    ) callconv(@"callconv") *Instance = null;
    var destroy_instance: ?*const fn (
        instance: *Instance,
    ) callconv(@"callconv") void = null;
    var get_slot: ?*const fn (
        instance: *Instance,
        name: [*:0]const u8,
    ) callconv(@"callconv") usize = null;
    var enumerate_adapters: ?*const fn (
        instance: *Instance,
        adapters_capacity: usize,
        adapters: ?[*]*Adapter,
        adapter_count: *usize,
    ) callconv(@"callconv") void = null;
    var create_device: ?*const fn (
        instance: *Instance,
        adapter: *Adapter,
    ) callconv(@"callconv") *Device = null;
    var destroy_device: ?*const fn (
        device: *Device,
    ) callconv(@"callconv") void = null;

    var slots: struct {
        adapter_info: usize = 0,
        create_surface_win32: usize = 0,
        create_surface_xlib: usize = 0,
        destroy_surface: usize = 0,
        surface_supported_usage: usize = 0,
        surface_supported_formats: usize = 0,
        surface_present_modes: usize = 0,
        host_from_device_pointer: usize = 0,
        alloc: usize = 0,
        free: usize = 0,
        descriptor_size_and_heap_align: usize = 0,
        store_descriptor: usize = 0,
        get_queue: usize = 0,
        texture_copy_granularity: usize = 0,
        create_command_pool: usize = 0,
        destroy_command_pool: usize = 0,
        reset_command_pool: usize = 0,
        start_command_recording: usize = 0,
        submit: usize = 0,
        submit_and_signal: usize = 0,
        create_timeline: usize = 0,
        destroy_timeline: usize = 0,
        wait_timeline_point: usize = 0,
        create_swapchain: usize = 0,
        destroy_swapchain: usize = 0,
        acquire_back_buffer: usize = 0,
        present: usize = 0,
        set_active_texture_heap: usize = 0,
        set_depth_stencil_state: usize = 0,
        set_pipeline: usize = 0,
        dispatch: usize = 0,
        dispatch_indirect: usize = 0,
        barrier: usize = 0,
        copy_texture_to_memory: usize = 0,
        copy_memory_to_texture: usize = 0,
        copy_memory: usize = 0,
        begin_render_pass: usize = 0,
        end_render_pass: usize = 0,
        set_scissor: usize = 0,
        set_viewport: usize = 0,
        draw: usize = 0,
        draw_indexed: usize = 0,
        draw_indexed_instanced: usize = 0,
        draw_indexed_instanced_indirect: usize = 0,
        draw_indirect: usize = 0,
        texture_size_align: usize = 0,
        texture_sample_count_max: usize = 0,
        create_texture: usize = 0,
        destroy_texture: usize = 0,
        texture_storage_descriptor: usize = 0,
        texture_view_descriptor: usize = 0,
        create_compute_pipeline: usize = 0,
        create_graphics_pipeline: usize = 0,
        destroy_pipeline: usize = 0,
        create_depth_stencil_state: usize = 0,
        destroy_depth_stencil_state: usize = 0,
    } = .{};

    fn loadGlobals(getSymbol: Symbol) void {
        create_instance = @ptrCast(getSymbol("scCreateInstance"));
        destroy_instance = @ptrCast(getSymbol("scDestroyInstance"));
        get_slot = @ptrCast(getSymbol("scGetSlot"));
        enumerate_adapters = @ptrCast(getSymbol("scEnumerateAdapters"));
        create_device = @ptrCast(getSymbol("scCreateDevice"));
        destroy_device = @ptrCast(getSymbol("scDestroyDevice"));
    }

    fn loadSlots(instance: *Instance) void {
        slots.adapter_info = get_slot.?(instance, "scAdapterInfo");
        slots.create_surface_win32 = get_slot.?(instance, "scCreateSurfaceWin32");
        slots.create_surface_xlib = get_slot.?(instance, "scCreateSurfaceXlib");
        slots.destroy_surface = get_slot.?(instance, "scDestroySurface");
        slots.surface_supported_usage = get_slot.?(instance, "scSurfaceSupportedUsage");
        slots.surface_supported_formats = get_slot.?(instance, "scSurfaceSupportedFormats");
        slots.surface_present_modes = get_slot.?(instance, "scSurfacePresentModes");
        slots.host_from_device_pointer = get_slot.?(instance, "scHostFromDevicePointer");
        slots.alloc = get_slot.?(instance, "scAlloc");
        slots.free = get_slot.?(instance, "scFree");
        slots.descriptor_size_and_heap_align = get_slot.?(instance, "scDescriptorSizeAndHeapAlign");
        slots.store_descriptor = get_slot.?(instance, "scStoreDescriptor");
        slots.get_queue = get_slot.?(instance, "scGetQueue");
        slots.texture_copy_granularity = get_slot.?(instance, "scTextureCopyGranularity");
        slots.create_command_pool = get_slot.?(instance, "scCreateCommandPool");
        slots.destroy_command_pool = get_slot.?(instance, "scDestroyCommandPool");
        slots.reset_command_pool = get_slot.?(instance, "scResetCommandPool");
        slots.start_command_recording = get_slot.?(instance, "scStartCommandRecording");
        slots.submit = get_slot.?(instance, "scSubmit");
        slots.submit_and_signal = get_slot.?(instance, "scSubmitAndSignal");
        slots.create_timeline = get_slot.?(instance, "scCreateTimeline");
        slots.destroy_timeline = get_slot.?(instance, "scDestroyTimeline");
        slots.wait_timeline_point = get_slot.?(instance, "scWaitTimelinePoint");
        slots.create_swapchain = get_slot.?(instance, "scCreateSwapchain");
        slots.destroy_swapchain = get_slot.?(instance, "scDestroySwapchain");
        slots.acquire_back_buffer = get_slot.?(instance, "scAcquireBackBuffer");
        slots.present = get_slot.?(instance, "scPresent");
        slots.set_active_texture_heap = get_slot.?(instance, "scSetActiveTextureHeap");
        slots.set_depth_stencil_state = get_slot.?(instance, "scSetDepthStencilState");
        slots.set_pipeline = get_slot.?(instance, "scSetPipeline");
        slots.dispatch = get_slot.?(instance, "scDispatch");
        slots.dispatch_indirect = get_slot.?(instance, "scDispatchIndirect");
        slots.barrier = get_slot.?(instance, "scBarrier");
        slots.copy_texture_to_memory = get_slot.?(instance, "scCopyTextureToMemory");
        slots.copy_memory_to_texture = get_slot.?(instance, "scCopyMemoryToTexture");
        slots.copy_memory = get_slot.?(instance, "scCopyMemory");
        slots.begin_render_pass = get_slot.?(instance, "scBeginRenderPass");
        slots.end_render_pass = get_slot.?(instance, "scEndRenderPass");
        slots.set_scissor = get_slot.?(instance, "scSetScissor");
        slots.set_viewport = get_slot.?(instance, "scSetViewport");
        slots.draw = get_slot.?(instance, "scDraw");
        slots.draw_indexed = get_slot.?(instance, "scDrawIndexed");
        slots.draw_indexed_instanced = get_slot.?(instance, "scDrawIndexedInstanced");
        slots.draw_indexed_instanced_indirect = get_slot.?(instance, "scDrawIndexedInstancedIndirect");
        slots.draw_indirect = get_slot.?(instance, "scDrawIndirect");
        slots.texture_size_align = get_slot.?(instance, "scTextureSizeAlign");
        slots.texture_sample_count_max = get_slot.?(instance, "scTextureSampleCountMax");
        slots.create_texture = get_slot.?(instance, "scCreateTexture");
        slots.destroy_texture = get_slot.?(instance, "scDestroyTexture");
        slots.texture_storage_descriptor = get_slot.?(instance, "scTextureStorageDescriptor");
        slots.texture_view_descriptor = get_slot.?(instance, "scTextureViewDescriptor");
        slots.create_compute_pipeline = get_slot.?(instance, "scCreateComputePipeline");
        slots.create_graphics_pipeline = get_slot.?(instance, "scCreateGraphicsPipeline");
        slots.destroy_pipeline = get_slot.?(instance, "scDestroyPipeline");
        slots.create_depth_stencil_state = get_slot.?(instance, "scCreateDepthStencilState");
        slots.destroy_depth_stencil_state = get_slot.?(instance, "scDestroyDepthStencilState");
    }
};
