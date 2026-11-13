// Generated file, do not edit.
// version: 0.1.0

const std = @import("std");
const sc = @import("sc.zig");
const Ptr = sc.Ptr;
const Slice = sc.Slice;
const @"callconv" = sc.@"callconv";

pub fn createInstance(
    allocator: ?*sc.HostAllocator,
    getSymbol: sc.Symbol,
) *sc.Instance {
    internal.loadGlobals(getSymbol);
    const f = internal.create_instance.?;
    const instance = f(
        allocator,
    );
    internal.loadSlots(instance);
    return instance;
}

pub fn destroyInstance(
    instance: *sc.Instance,
) void {
    const f = internal.destroy_instance.?;
    return f(
        instance,
    );
}

pub fn enumerateAdapters(
    instance: *sc.Instance,
    adapters: ?[]*sc.Adapter,
) usize {
    const f = internal.enumerate_adapters.?;
    var adapter_count: usize = undefined;
    f(
        instance,
        @intCast((if (adapters) |unwrapped| unwrapped.len else 0)),
        (if (adapters) |unwrapped| unwrapped.ptr else null),
        &adapter_count,
    );
    return adapter_count;
}

pub fn enumerateAdaptersAlloc(
    instance: *sc.Instance,
    gpa: std.mem.Allocator,
) error{
    OutOfMemory,
}![]*sc.Adapter {
    var adapters: []*sc.Adapter = &.{};
    errdefer gpa.free(adapters);
    while (true) {
        const adapter_count = enumerateAdapters(
            instance,
            adapters,
        );
        if (adapter_count <= adapters.len) return gpa.realloc(adapters, adapter_count);
        adapters = try gpa.realloc(adapters, adapter_count);
    }
}

pub fn createDevice(
    instance: *sc.Instance,
    adapter: *sc.Adapter,
) *sc.Device {
    const f = internal.create_device.?;
    return f(
        instance,
        adapter,
    );
}

pub fn destroyDevice(
    device: *sc.Device,
) void {
    const f = internal.destroy_device.?;
    return f(
        device,
    );
}

pub fn adapterInfo(
    instance: *sc.Instance,
    adapter: *sc.Adapter,
) sc.AdapterInfo {
    const f: *const fn (
        instance: *sc.Instance,
        adapter: *sc.Adapter,
    ) callconv(@"callconv") sc.AdapterInfo = @ptrCast(internal.table(instance)[internal.slots.adapter_info]);
    return f(
        instance,
        adapter,
    );
}

pub fn createSurfaceWin32(
    device: *sc.Device,
    desc: sc.SurfaceWin32Desc,
) *sc.Surface {
    const f: *const fn (
        device: *sc.Device,
        desc: sc.SurfaceWin32Desc,
    ) callconv(@"callconv") *sc.Surface = @ptrCast(internal.table(device)[internal.slots.create_surface_win32]);
    return f(
        device,
        desc,
    );
}

pub fn createSurfaceXlib(
    device: *sc.Device,
    desc: sc.SurfaceXlibDesc,
) *sc.Surface {
    const f: *const fn (
        device: *sc.Device,
        desc: sc.SurfaceXlibDesc,
    ) callconv(@"callconv") *sc.Surface = @ptrCast(internal.table(device)[internal.slots.create_surface_xlib]);
    return f(
        device,
        desc,
    );
}

pub fn destroySurface(
    surface: *sc.Surface,
) void {
    const f: *const fn (
        surface: *sc.Surface,
    ) callconv(@"callconv") void = @ptrCast(internal.table(surface)[internal.slots.destroy_surface]);
    return f(
        surface,
    );
}

pub fn surfaceSupportedUsage(
    surface: *sc.Surface,
) sc.TextureUsage {
    const f: *const fn (
        surface: *sc.Surface,
    ) callconv(@"callconv") sc.TextureUsage = @ptrCast(internal.table(surface)[internal.slots.surface_supported_usage]);
    return f(
        surface,
    );
}

pub fn surfaceSupportedFormats(
    surface: *sc.Surface,
    color_space: sc.ColorSpace,
    formats: ?[]sc.Format,
) usize {
    const f: *const fn (
        surface: *sc.Surface,
        color_space: sc.ColorSpace,
        formats_capacity: usize,
        formats: ?[*]sc.Format,
        format_count: *usize,
    ) callconv(@"callconv") void = @ptrCast(internal.table(surface)[internal.slots.surface_supported_formats]);
    var format_count: usize = undefined;
    f(
        surface,
        color_space,
        @intCast((if (formats) |unwrapped| unwrapped.len else 0)),
        (if (formats) |unwrapped| unwrapped.ptr else null),
        &format_count,
    );
    return format_count;
}

pub fn surfaceSupportedFormatsAlloc(
    surface: *sc.Surface,
    color_space: sc.ColorSpace,
    gpa: std.mem.Allocator,
) error{
    OutOfMemory,
}![]sc.Format {
    var formats: []sc.Format = &.{};
    errdefer gpa.free(formats);
    while (true) {
        const format_count = surfaceSupportedFormats(
            surface,
            color_space,
            formats,
        );
        if (format_count <= formats.len) return gpa.realloc(formats, format_count);
        formats = try gpa.realloc(formats, format_count);
    }
}

pub fn surfacePresentModes(
    surface: *sc.Surface,
    present_modes: ?[]sc.PresentMode,
) usize {
    const f: *const fn (
        surface: *sc.Surface,
        present_modes_capacity: usize,
        present_modes: ?[*]sc.PresentMode,
        present_mode_count: *usize,
    ) callconv(@"callconv") void = @ptrCast(internal.table(surface)[internal.slots.surface_present_modes]);
    var present_mode_count: usize = undefined;
    f(
        surface,
        @intCast((if (present_modes) |unwrapped| unwrapped.len else 0)),
        (if (present_modes) |unwrapped| unwrapped.ptr else null),
        &present_mode_count,
    );
    return present_mode_count;
}

pub fn surfacePresentModesAlloc(
    surface: *sc.Surface,
    gpa: std.mem.Allocator,
) error{
    OutOfMemory,
}![]sc.PresentMode {
    var present_modes: []sc.PresentMode = &.{};
    errdefer gpa.free(present_modes);
    while (true) {
        const present_mode_count = surfacePresentModes(
            surface,
            present_modes,
        );
        if (present_mode_count <= present_modes.len) return gpa.realloc(present_modes, present_mode_count);
        present_modes = try gpa.realloc(present_modes, present_mode_count);
    }
}

pub fn hostFromDevicePointer(
    device: *sc.Device,
    address: Ptr(.many, u8, .{}),
) *anyopaque {
    const f: *const fn (
        device: *sc.Device,
        address: Ptr(.many, u8, .{}),
    ) callconv(@"callconv") *anyopaque = @ptrCast(internal.table(device)[internal.slots.host_from_device_pointer]);
    return f(
        device,
        address,
    );
}

pub fn alloc(
    device: *sc.Device,
    size: usize,
    alignment: usize,
    memory: sc.MemoryKind,
) error{
    OutOfMemory,
    OutOfDeviceMemory,
}!sc.HostDeviceAddress {
    const f: *const fn (
        device: *sc.Device,
        size: usize,
        alignment: usize,
        memory: sc.MemoryKind,
        device_mapping: *sc.HostDeviceAddress,
    ) callconv(@"callconv") sc.Result = @ptrCast(internal.table(device)[internal.slots.alloc]);
    var device_mapping: sc.HostDeviceAddress = undefined;
    const result = f(
        device,
        size,
        alignment,
        memory,
        &device_mapping,
    );
    switch (result) {
        .ok => {},
        .out_of_memory => return error.OutOfMemory,
        .out_of_device_memory => return error.OutOfDeviceMemory,
        else => unreachable,
    }
    return device_mapping;
}

pub fn free(
    device: *sc.Device,
    address: Ptr(.many, u8, .{}),
) void {
    const f: *const fn (
        device: *sc.Device,
        address: Ptr(.many, u8, .{}),
    ) callconv(@"callconv") void = @ptrCast(internal.table(device)[internal.slots.free]);
    return f(
        device,
        address,
    );
}

pub fn descriptorSizeAndHeapAlign(
    device: *sc.Device,
) sc.SizeAlign {
    const f: *const fn (
        device: *sc.Device,
    ) callconv(@"callconv") sc.SizeAlign = @ptrCast(internal.table(device)[internal.slots.descriptor_size_and_heap_align]);
    return f(
        device,
    );
}

pub fn storeDescriptor(
    device: *sc.Device,
    descriptor: *const sc.Descriptor,
    descriptor_heap: [*]u8,
    index: usize,
) void {
    const f: *const fn (
        device: *sc.Device,
        descriptor: *const sc.Descriptor,
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
    device: *sc.Device,
    queue_kind: sc.QueueKind,
) *sc.Queue {
    const f: *const fn (
        device: *sc.Device,
        queue_kind: sc.QueueKind,
    ) callconv(@"callconv") *sc.Queue = @ptrCast(internal.table(device)[internal.slots.get_queue]);
    return f(
        device,
        queue_kind,
    );
}

/// Texture copies recorded for this queue must have an offset that is a multiple of the granularity times the format's block extent, and an extent that is a multiple of it unless it reaches the edge of the mip. Never 0, and always (1, 1, 1) for graphics and compute queues.
pub fn textureCopyGranularity(
    queue: *sc.Queue,
) sc.Extent3D {
    const f: *const fn (
        queue: *sc.Queue,
    ) callconv(@"callconv") sc.Extent3D = @ptrCast(internal.table(queue)[internal.slots.texture_copy_granularity]);
    return f(
        queue,
    );
}

pub fn createCommandPool(
    queue: *sc.Queue,
) error{
    OutOfMemory,
    OutOfDeviceMemory,
    Unknown,
}!*sc.CommandPool {
    const f: *const fn (
        queue: *sc.Queue,
        command_pool: **sc.CommandPool,
    ) callconv(@"callconv") sc.Result = @ptrCast(internal.table(queue)[internal.slots.create_command_pool]);
    var command_pool: *sc.CommandPool = undefined;
    const result = f(
        queue,
        &command_pool,
    );
    switch (result) {
        .ok => {},
        .out_of_memory => return error.OutOfMemory,
        .out_of_device_memory => return error.OutOfDeviceMemory,
        .unknown => return error.Unknown,
        else => unreachable,
    }
    return command_pool;
}

/// Submitted command buffers of the pool must have completed.
pub fn destroyCommandPool(
    command_pool: *sc.CommandPool,
) void {
    const f: *const fn (
        command_pool: *sc.CommandPool,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_pool)[internal.slots.destroy_command_pool]);
    return f(
        command_pool,
    );
}

/// Invalidates every command buffer of the pool and recycles their memory. Submitted command buffers of the pool must have completed.
pub fn resetCommandPool(
    command_pool: *sc.CommandPool,
) error{
    OutOfDeviceMemory,
    Unknown,
}!void {
    const f: *const fn (
        command_pool: *sc.CommandPool,
    ) callconv(@"callconv") sc.Result = @ptrCast(internal.table(command_pool)[internal.slots.reset_command_pool]);
    const result = f(
        command_pool,
    );
    switch (result) {
        .ok => {},
        .out_of_device_memory => return error.OutOfDeviceMemory,
        .unknown => return error.Unknown,
        else => unreachable,
    }
}

/// The command buffer stays valid until its pool is reset or destroyed, it can be submitted once to the queue of the pool.
pub fn startCommandRecording(
    command_pool: *sc.CommandPool,
) error{
    OutOfMemory,
    OutOfDeviceMemory,
    Unknown,
}!*sc.CommandBuffer {
    const f: *const fn (
        command_pool: *sc.CommandPool,
        command_buffer: **sc.CommandBuffer,
    ) callconv(@"callconv") sc.Result = @ptrCast(internal.table(command_pool)[internal.slots.start_command_recording]);
    var command_buffer: *sc.CommandBuffer = undefined;
    const result = f(
        command_pool,
        &command_buffer,
    );
    switch (result) {
        .ok => {},
        .out_of_memory => return error.OutOfMemory,
        .out_of_device_memory => return error.OutOfDeviceMemory,
        .unknown => return error.Unknown,
        else => unreachable,
    }
    return command_buffer;
}

pub fn submit(
    queue: *sc.Queue,
    command_buffers: []const *sc.CommandBuffer,
    waits: []const sc.TimelinePoint,
) error{
    OutOfDeviceMemory,
    OutOfMemory,
    DeviceLost,
    Unknown,
}!void {
    const f: *const fn (
        queue: *sc.Queue,
        command_buffer_count: usize,
        command_buffers: [*]const *sc.CommandBuffer,
        wait_count: usize,
        waits: [*]const sc.TimelinePoint,
    ) callconv(@"callconv") sc.Result = @ptrCast(internal.table(queue)[internal.slots.submit]);
    const result = f(
        queue,
        @intCast(command_buffers.len),
        command_buffers.ptr,
        @intCast(waits.len),
        waits.ptr,
    );
    switch (result) {
        .ok => {},
        .out_of_device_memory => return error.OutOfDeviceMemory,
        .out_of_memory => return error.OutOfMemory,
        .device_lost => return error.DeviceLost,
        .unknown => return error.Unknown,
        else => unreachable,
    }
}

pub fn submitAndSignal(
    queue: *sc.Queue,
    command_buffers: []const *sc.CommandBuffer,
    waits: []const sc.TimelinePoint,
    signal: sc.TimelinePoint,
) error{
    OutOfDeviceMemory,
    OutOfMemory,
    DeviceLost,
    Unknown,
}!void {
    const f: *const fn (
        queue: *sc.Queue,
        command_buffer_count: usize,
        command_buffers: [*]const *sc.CommandBuffer,
        wait_count: usize,
        waits: [*]const sc.TimelinePoint,
        signal: sc.TimelinePoint,
    ) callconv(@"callconv") sc.Result = @ptrCast(internal.table(queue)[internal.slots.submit_and_signal]);
    const result = f(
        queue,
        @intCast(command_buffers.len),
        command_buffers.ptr,
        @intCast(waits.len),
        waits.ptr,
        signal,
    );
    switch (result) {
        .ok => {},
        .out_of_device_memory => return error.OutOfDeviceMemory,
        .out_of_memory => return error.OutOfMemory,
        .device_lost => return error.DeviceLost,
        .unknown => return error.Unknown,
        else => unreachable,
    }
}

pub fn createTimeline(
    device: *sc.Device,
    initial_value: u64,
) error{
    OutOfMemory,
    OutOfDeviceMemory,
    Unknown,
}!*sc.Timeline {
    const f: *const fn (
        device: *sc.Device,
        initial_value: u64,
        timeline: **sc.Timeline,
    ) callconv(@"callconv") sc.Result = @ptrCast(internal.table(device)[internal.slots.create_timeline]);
    var timeline: *sc.Timeline = undefined;
    const result = f(
        device,
        initial_value,
        &timeline,
    );
    switch (result) {
        .ok => {},
        .out_of_memory => return error.OutOfMemory,
        .out_of_device_memory => return error.OutOfDeviceMemory,
        .unknown => return error.Unknown,
        else => unreachable,
    }
    return timeline;
}

pub fn destroyTimeline(
    timeline: *sc.Timeline,
) void {
    const f: *const fn (
        timeline: *sc.Timeline,
    ) callconv(@"callconv") void = @ptrCast(internal.table(timeline)[internal.slots.destroy_timeline]);
    return f(
        timeline,
    );
}

pub fn waitTimelinePoint(
    point: sc.TimelinePoint,
) error{
    OutOfDeviceMemory,
    OutOfMemory,
    DeviceLost,
    Unknown,
}!void {
    const f: *const fn (
        point: sc.TimelinePoint,
    ) callconv(@"callconv") sc.Result = @ptrCast(internal.table(point.timeline)[internal.slots.wait_timeline_point]);
    const result = f(
        point,
    );
    switch (result) {
        .ok => {},
        .out_of_device_memory => return error.OutOfDeviceMemory,
        .out_of_memory => return error.OutOfMemory,
        .device_lost => return error.DeviceLost,
        .unknown => return error.Unknown,
        else => unreachable,
    }
}

pub fn createSwapchain(
    queue: *sc.Queue,
    surface: *sc.Surface,
    desc: sc.SwapchainDesc,
) error{
    OutOfDeviceMemory,
    OutOfMemory,
    SurfaceLost,
    Unknown,
}!*sc.Swapchain {
    const f: *const fn (
        queue: *sc.Queue,
        surface: *sc.Surface,
        desc: sc.SwapchainDesc,
        swapchain: **sc.Swapchain,
    ) callconv(@"callconv") sc.Result = @ptrCast(internal.table(queue)[internal.slots.create_swapchain]);
    var swapchain: *sc.Swapchain = undefined;
    const result = f(
        queue,
        surface,
        desc,
        &swapchain,
    );
    switch (result) {
        .ok => {},
        .out_of_device_memory => return error.OutOfDeviceMemory,
        .out_of_memory => return error.OutOfMemory,
        .surface_lost => return error.SurfaceLost,
        .unknown => return error.Unknown,
        else => unreachable,
    }
    return swapchain;
}

pub fn destroySwapchain(
    swapchain: *sc.Swapchain,
) void {
    const f: *const fn (
        swapchain: *sc.Swapchain,
    ) callconv(@"callconv") void = @ptrCast(internal.table(swapchain)[internal.slots.destroy_swapchain]);
    return f(
        swapchain,
    );
}

pub fn acquireBackBuffer(
    swapchain: *sc.Swapchain,
    extent: sc.Extent2D,
) error{
    OutOfMemory,
    OutOfDeviceMemory,
    DeviceLost,
    SurfaceLost,
    NoBackbuffer,
    Unknown,
}!sc.BackBuffer {
    const f: *const fn (
        swapchain: *sc.Swapchain,
        extent: sc.Extent2D,
        back_buffer: *sc.BackBuffer,
    ) callconv(@"callconv") sc.Result = @ptrCast(internal.table(swapchain)[internal.slots.acquire_back_buffer]);
    var back_buffer: sc.BackBuffer = undefined;
    const result = f(
        swapchain,
        extent,
        &back_buffer,
    );
    switch (result) {
        .ok => {},
        .out_of_memory => return error.OutOfMemory,
        .out_of_device_memory => return error.OutOfDeviceMemory,
        .device_lost => return error.DeviceLost,
        .surface_lost => return error.SurfaceLost,
        .no_backbuffer => return error.NoBackbuffer,
        .unknown => return error.Unknown,
        else => unreachable,
    }
    return back_buffer;
}

pub fn present(
    swapchain: *sc.Swapchain,
) error{
    OutOfMemory,
    OutOfDeviceMemory,
    DeviceLost,
    SurfaceLost,
    Unknown,
}!void {
    const f: *const fn (
        swapchain: *sc.Swapchain,
    ) callconv(@"callconv") sc.Result = @ptrCast(internal.table(swapchain)[internal.slots.present]);
    const result = f(
        swapchain,
    );
    switch (result) {
        .ok => {},
        .out_of_memory => return error.OutOfMemory,
        .out_of_device_memory => return error.OutOfDeviceMemory,
        .device_lost => return error.DeviceLost,
        .surface_lost => return error.SurfaceLost,
        .unknown => return error.Unknown,
        else => unreachable,
    }
}

pub fn setActiveTextureHeap(
    command_buffer: *sc.CommandBuffer,
    heap_address: Ptr(.many, u8, .{}),
) void {
    const f: *const fn (
        command_buffer: *sc.CommandBuffer,
        heap_address: Ptr(.many, u8, .{}),
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.set_active_texture_heap]);
    return f(
        command_buffer,
        heap_address,
    );
}

pub fn setDepthStencilState(
    command_buffer: *sc.CommandBuffer,
    depth_stencil_state: *sc.DepthStencilState,
) void {
    const f: *const fn (
        command_buffer: *sc.CommandBuffer,
        depth_stencil_state: *sc.DepthStencilState,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.set_depth_stencil_state]);
    return f(
        command_buffer,
        depth_stencil_state,
    );
}

pub fn setPipeline(
    command_buffer: *sc.CommandBuffer,
    pipeline: *sc.Pipeline,
) void {
    const f: *const fn (
        command_buffer: *sc.CommandBuffer,
        pipeline: *sc.Pipeline,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.set_pipeline]);
    return f(
        command_buffer,
        pipeline,
    );
}

pub fn dispatch(
    command_buffer: *sc.CommandBuffer,
    data: Ptr(.one, anyopaque, .{}),
    x: u32,
    y: u32,
    z: u32,
) void {
    const f: *const fn (
        command_buffer: *sc.CommandBuffer,
        data: Ptr(.one, anyopaque, .{}),
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
    command_buffer: *sc.CommandBuffer,
    data: Ptr(.one, anyopaque, .{}),
    arguments: Ptr(.one, sc.DispatchArguments, .{}),
) void {
    const f: *const fn (
        command_buffer: *sc.CommandBuffer,
        data: Ptr(.one, anyopaque, .{}),
        arguments: Ptr(.one, sc.DispatchArguments, .{}),
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.dispatch_indirect]);
    return f(
        command_buffer,
        data,
        arguments,
    );
}

pub fn barrier(
    command_buffer: *sc.CommandBuffer,
    before: sc.Stage,
    after: sc.Stage,
    hazard: sc.Hazard,
) void {
    const f: *const fn (
        command_buffer: *sc.CommandBuffer,
        before: sc.Stage,
        after: sc.Stage,
        hazard: sc.Hazard,
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
    command_buffer: *sc.CommandBuffer,
    source_texture: *sc.Texture,
    destination: Slice(u8, .{ .@"align" = .@"16" }),
    desc: sc.TextureCopyDesc,
) void {
    const f: *const fn (
        command_buffer: *sc.CommandBuffer,
        source_texture: *sc.Texture,
        destination: Ptr(.many, u8, .{ .@"align" = .@"16" }),
        size: usize,
        desc: sc.TextureCopyDesc,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.copy_texture_to_memory]);
    return f(
        command_buffer,
        source_texture,
        destination.ptr,
        @intCast(destination.len),
        desc,
    );
}

pub fn copyMemoryToTexture(
    command_buffer: *sc.CommandBuffer,
    source: Slice(u8, .{}),
    destination_texture: *sc.Texture,
    desc: sc.TextureCopyDesc,
) void {
    const f: *const fn (
        command_buffer: *sc.CommandBuffer,
        source: Ptr(.many, u8, .{}),
        size: usize,
        destination_texture: *sc.Texture,
        desc: sc.TextureCopyDesc,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.copy_memory_to_texture]);
    return f(
        command_buffer,
        source.ptr,
        @intCast(source.len),
        destination_texture,
        desc,
    );
}

pub fn copyMemory(
    command_buffer: *sc.CommandBuffer,
    source: Slice(u8, .{}),
    destination: Slice(u8, .{}),
) void {
    const f: *const fn (
        command_buffer: *sc.CommandBuffer,
        source: Ptr(.many, u8, .{}),
        destination: Ptr(.many, u8, .{}),
        size: usize,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.copy_memory]);
    std.debug.assert(source.len == destination.len);
    return f(
        command_buffer,
        source.ptr,
        destination.ptr,
        @intCast(source.len),
    );
}

pub fn beginRenderPass(
    command_buffer: *sc.CommandBuffer,
    desc: sc.RenderPassDesc,
) void {
    const f: *const fn (
        command_buffer: *sc.CommandBuffer,
        desc: sc.RenderPassDesc,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.begin_render_pass]);
    return f(
        command_buffer,
        desc,
    );
}

pub fn endRenderPass(
    command_buffer: *sc.CommandBuffer,
) void {
    const f: *const fn (
        command_buffer: *sc.CommandBuffer,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.end_render_pass]);
    return f(
        command_buffer,
    );
}

/// Only valid inside a render pass. Beginning a render pass resets the scissor to the full render target.
pub fn setScissor(
    command_buffer: *sc.CommandBuffer,
    rect: sc.Rect2D,
) void {
    const f: *const fn (
        command_buffer: *sc.CommandBuffer,
        rect: sc.Rect2D,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.set_scissor]);
    return f(
        command_buffer,
        rect,
    );
}

/// Only valid inside a render pass. Beginning a render pass resets the viewport to the full render target with a [0, 1] depth range.
pub fn setViewport(
    command_buffer: *sc.CommandBuffer,
    viewport: sc.Viewport,
) void {
    const f: *const fn (
        command_buffer: *sc.CommandBuffer,
        viewport: sc.Viewport,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.set_viewport]);
    return f(
        command_buffer,
        viewport,
    );
}

pub fn draw(
    command_buffer: *sc.CommandBuffer,
    vertex_data: Ptr(.one, anyopaque, .{}),
    pixel_data: Ptr(.one, anyopaque, .{}),
    vertex_count: u32,
    instance_count: u32,
) void {
    const f: *const fn (
        command_buffer: *sc.CommandBuffer,
        vertex_data: Ptr(.one, anyopaque, .{}),
        pixel_data: Ptr(.one, anyopaque, .{}),
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
    command_buffer: *sc.CommandBuffer,
    vertex_data: Ptr(.one, anyopaque, .{}),
    pixel_data: Ptr(.one, anyopaque, .{}),
    index_type: sc.IndexType,
    indices: Ptr(.many, u8, .{}),
    index_count: u32,
) void {
    const f: *const fn (
        command_buffer: *sc.CommandBuffer,
        vertex_data: Ptr(.one, anyopaque, .{}),
        pixel_data: Ptr(.one, anyopaque, .{}),
        index_type: sc.IndexType,
        indices: Ptr(.many, u8, .{}),
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
    command_buffer: *sc.CommandBuffer,
    vertex_data: Ptr(.one, anyopaque, .{}),
    pixel_data: Ptr(.one, anyopaque, .{}),
    index_type: sc.IndexType,
    indices: Ptr(.many, u8, .{}),
    index_count: u32,
    instance_count: u32,
) void {
    const f: *const fn (
        command_buffer: *sc.CommandBuffer,
        vertex_data: Ptr(.one, anyopaque, .{}),
        pixel_data: Ptr(.one, anyopaque, .{}),
        index_type: sc.IndexType,
        indices: Ptr(.many, u8, .{}),
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
    command_buffer: *sc.CommandBuffer,
    vertex_data: Ptr(.one, anyopaque, .{}),
    pixel_data: Ptr(.one, anyopaque, .{}),
    index_type: sc.IndexType,
    indices: Ptr(.many, u8, .{}),
    arguments: Slice(sc.DrawIndexedArguments, .{}),
) void {
    const f: *const fn (
        command_buffer: *sc.CommandBuffer,
        vertex_data: Ptr(.one, anyopaque, .{}),
        pixel_data: Ptr(.one, anyopaque, .{}),
        index_type: sc.IndexType,
        indices: Ptr(.many, u8, .{}),
        arguments: Ptr(.many, sc.DrawIndexedArguments, .{}),
        draw_count: u32,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.draw_indexed_instanced_indirect]);
    return f(
        command_buffer,
        vertex_data,
        pixel_data,
        index_type,
        indices,
        arguments.ptr,
        @intCast(arguments.len),
    );
}

/// Use SV_DrawIndex in the shader to tell the draws apart.
pub fn drawIndirect(
    command_buffer: *sc.CommandBuffer,
    vertex_data: Ptr(.one, anyopaque, .{}),
    pixel_data: Ptr(.one, anyopaque, .{}),
    arguments: Slice(sc.DrawArguments, .{}),
) void {
    const f: *const fn (
        command_buffer: *sc.CommandBuffer,
        vertex_data: Ptr(.one, anyopaque, .{}),
        pixel_data: Ptr(.one, anyopaque, .{}),
        arguments: Ptr(.many, sc.DrawArguments, .{}),
        draw_count: u32,
    ) callconv(@"callconv") void = @ptrCast(internal.table(command_buffer)[internal.slots.draw_indirect]);
    return f(
        command_buffer,
        vertex_data,
        pixel_data,
        arguments.ptr,
        @intCast(arguments.len),
    );
}

pub fn textureSizeAlign(
    device: *sc.Device,
    desc: sc.TextureDesc,
) sc.SizeAlign {
    const f: *const fn (
        device: *sc.Device,
        desc: sc.TextureDesc,
    ) callconv(@"callconv") sc.SizeAlign = @ptrCast(internal.table(device)[internal.slots.texture_size_align]);
    return f(
        device,
        desc,
    );
}

/// Highest sample count the texture can be created with, every power of two below it is supported too. At most 8, and 0 when the texture can't be created at all. At least 4 for attachments with a non-integer format.
pub fn textureSampleCountMax(
    device: *sc.Device,
    desc: sc.TextureDesc,
) u32 {
    const f: *const fn (
        device: *sc.Device,
        desc: sc.TextureDesc,
    ) callconv(@"callconv") u32 = @ptrCast(internal.table(device)[internal.slots.texture_sample_count_max]);
    return f(
        device,
        desc,
    );
}

pub fn createTexture(
    device: *sc.Device,
    desc: sc.TextureDesc,
    data: Ptr(.many, u8, .{}),
) error{
    OutOfMemory,
    OutOfDeviceMemory,
    Unknown,
}!*sc.Texture {
    const f: *const fn (
        device: *sc.Device,
        desc: sc.TextureDesc,
        data: Ptr(.many, u8, .{}),
        texture: **sc.Texture,
    ) callconv(@"callconv") sc.Result = @ptrCast(internal.table(device)[internal.slots.create_texture]);
    var texture: *sc.Texture = undefined;
    const result = f(
        device,
        desc,
        data,
        &texture,
    );
    switch (result) {
        .ok => {},
        .out_of_memory => return error.OutOfMemory,
        .out_of_device_memory => return error.OutOfDeviceMemory,
        .unknown => return error.Unknown,
        else => unreachable,
    }
    return texture;
}

pub fn destroyTexture(
    texture: *sc.Texture,
) void {
    const f: *const fn (
        texture: *sc.Texture,
    ) callconv(@"callconv") void = @ptrCast(internal.table(texture)[internal.slots.destroy_texture]);
    return f(
        texture,
    );
}

pub fn textureStorageDescriptor(
    texture: *sc.Texture,
    desc: sc.TextureViewDesc,
) error{
    OutOfMemory,
    OutOfDeviceMemory,
    Unknown,
}!sc.Descriptor {
    const f: *const fn (
        texture: *sc.Texture,
        desc: sc.TextureViewDesc,
        descriptor: *sc.Descriptor,
    ) callconv(@"callconv") sc.Result = @ptrCast(internal.table(texture)[internal.slots.texture_storage_descriptor]);
    var descriptor: sc.Descriptor = undefined;
    const result = f(
        texture,
        desc,
        &descriptor,
    );
    switch (result) {
        .ok => {},
        .out_of_memory => return error.OutOfMemory,
        .out_of_device_memory => return error.OutOfDeviceMemory,
        .unknown => return error.Unknown,
        else => unreachable,
    }
    return descriptor;
}

pub fn textureViewDescriptor(
    texture: *sc.Texture,
    desc: sc.TextureViewDesc,
) error{
    OutOfMemory,
    OutOfDeviceMemory,
    Unknown,
}!sc.Descriptor {
    const f: *const fn (
        texture: *sc.Texture,
        desc: sc.TextureViewDesc,
        descriptor: *sc.Descriptor,
    ) callconv(@"callconv") sc.Result = @ptrCast(internal.table(texture)[internal.slots.texture_view_descriptor]);
    var descriptor: sc.Descriptor = undefined;
    const result = f(
        texture,
        desc,
        &descriptor,
    );
    switch (result) {
        .ok => {},
        .out_of_memory => return error.OutOfMemory,
        .out_of_device_memory => return error.OutOfDeviceMemory,
        .unknown => return error.Unknown,
        else => unreachable,
    }
    return descriptor;
}

pub fn createComputePipeline(
    device: *sc.Device,
    ir: []const u8,
) error{
    OutOfMemory,
    OutOfDeviceMemory,
    MalformedScir,
    UnsupportedScirVersion,
    UnsupportedScirBytecode,
    Unknown,
}!*sc.Pipeline {
    const f: *const fn (
        device: *sc.Device,
        ir_size: usize,
        ir: [*]const u8,
        pipeline: **sc.Pipeline,
    ) callconv(@"callconv") sc.Result = @ptrCast(internal.table(device)[internal.slots.create_compute_pipeline]);
    var pipeline: *sc.Pipeline = undefined;
    const result = f(
        device,
        @intCast(ir.len),
        ir.ptr,
        &pipeline,
    );
    switch (result) {
        .ok => {},
        .out_of_memory => return error.OutOfMemory,
        .out_of_device_memory => return error.OutOfDeviceMemory,
        .malformed_scir => return error.MalformedScir,
        .unsupported_scir_version => return error.UnsupportedScirVersion,
        .unsupported_scir_bytecode => return error.UnsupportedScirBytecode,
        .unknown => return error.Unknown,
        else => unreachable,
    }
    return pipeline;
}

pub fn createGraphicsPipeline(
    device: *sc.Device,
    vertex_ir: []const u8,
    pixel_ir: []const u8,
    desc: sc.GraphicsPipelineDesc,
) error{
    OutOfMemory,
    OutOfDeviceMemory,
    MalformedScir,
    UnsupportedScirVersion,
    UnsupportedScirBytecode,
    Unknown,
}!*sc.Pipeline {
    const f: *const fn (
        device: *sc.Device,
        vertex_ir_size: usize,
        vertex_ir: [*]const u8,
        pixel_ir_size: usize,
        pixel_ir: [*]const u8,
        desc: sc.GraphicsPipelineDesc,
        pipeline: **sc.Pipeline,
    ) callconv(@"callconv") sc.Result = @ptrCast(internal.table(device)[internal.slots.create_graphics_pipeline]);
    var pipeline: *sc.Pipeline = undefined;
    const result = f(
        device,
        @intCast(vertex_ir.len),
        vertex_ir.ptr,
        @intCast(pixel_ir.len),
        pixel_ir.ptr,
        desc,
        &pipeline,
    );
    switch (result) {
        .ok => {},
        .out_of_memory => return error.OutOfMemory,
        .out_of_device_memory => return error.OutOfDeviceMemory,
        .malformed_scir => return error.MalformedScir,
        .unsupported_scir_version => return error.UnsupportedScirVersion,
        .unsupported_scir_bytecode => return error.UnsupportedScirBytecode,
        .unknown => return error.Unknown,
        else => unreachable,
    }
    return pipeline;
}

pub fn destroyPipeline(
    pipeline: *sc.Pipeline,
) void {
    const f: *const fn (
        pipeline: *sc.Pipeline,
    ) callconv(@"callconv") void = @ptrCast(internal.table(pipeline)[internal.slots.destroy_pipeline]);
    return f(
        pipeline,
    );
}

pub fn createDepthStencilState(
    device: *sc.Device,
    desc: sc.DepthStencilDesc,
) error{
    OutOfMemory,
}!*sc.DepthStencilState {
    const f: *const fn (
        device: *sc.Device,
        desc: sc.DepthStencilDesc,
        depth_stencil_state: **sc.DepthStencilState,
    ) callconv(@"callconv") sc.Result = @ptrCast(internal.table(device)[internal.slots.create_depth_stencil_state]);
    var depth_stencil_state: *sc.DepthStencilState = undefined;
    const result = f(
        device,
        desc,
        &depth_stencil_state,
    );
    switch (result) {
        .ok => {},
        .out_of_memory => return error.OutOfMemory,
        else => unreachable,
    }
    return depth_stencil_state;
}

pub fn destroyDepthStencilState(
    depth_stencil_state: *sc.DepthStencilState,
) void {
    const f: *const fn (
        depth_stencil_state: *sc.DepthStencilState,
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
        allocator: ?*sc.HostAllocator,
    ) callconv(@"callconv") *sc.Instance = null;
    var destroy_instance: ?*const fn (
        instance: *sc.Instance,
    ) callconv(@"callconv") void = null;
    var get_slot: ?*const fn (
        instance: *sc.Instance,
        name: [*:0]const u8,
    ) callconv(@"callconv") usize = null;
    var enumerate_adapters: ?*const fn (
        instance: *sc.Instance,
        adapters_capacity: usize,
        adapters: ?[*]*sc.Adapter,
        adapter_count: *usize,
    ) callconv(@"callconv") void = null;
    var create_device: ?*const fn (
        instance: *sc.Instance,
        adapter: *sc.Adapter,
    ) callconv(@"callconv") *sc.Device = null;
    var destroy_device: ?*const fn (
        device: *sc.Device,
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

    fn loadGlobals(getSymbol: sc.Symbol) void {
        create_instance = @ptrCast(getSymbol("scCreateInstance"));
        destroy_instance = @ptrCast(getSymbol("scDestroyInstance"));
        get_slot = @ptrCast(getSymbol("scGetSlot"));
        enumerate_adapters = @ptrCast(getSymbol("scEnumerateAdapters"));
        create_device = @ptrCast(getSymbol("scCreateDevice"));
        destroy_device = @ptrCast(getSymbol("scDestroyDevice"));
    }

    fn loadSlots(instance: *sc.Instance) void {
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
