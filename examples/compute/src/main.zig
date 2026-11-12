const std = @import("std");
const sc = @import("scoria");
const c = @import("c");
const common = @import("common");

const scSymbol = @extern(sc.Symbol, .{ .name = "scSymbol" });

const frames_in_flight = 2;
const workgroup_size = 8;
const descriptor_count_max = 65536;

const Data = extern struct {
    output_texture: u32,
    time: f32,
};

const Renderer = struct {
    io: std.Io,
    window: *c.SDL_Window,
    device: *sc.Device,
    queue: *sc.Queue,
    swapchain: *sc.Swapchain,
    frame_timeline: *sc.Timeline,
    frame_index: u64,
    descriptor_heap: sc.heap.Allocation(u8, null),
    data_maps: [frames_in_flight]sc.heap.AllocationOne(Data, null),
    pipeline: *sc.Pipeline,
    start: std.Io.Timestamp,
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();

    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) return error.SdlInit;
    defer c.SDL_Quit();

    const window = c.SDL_CreateWindow("compute", 512, 512, c.SDL_WINDOW_VULKAN | c.SDL_WINDOW_RESIZABLE) orelse return error.SdlCreateWindow;
    defer c.SDL_DestroyWindow(window);

    const instance = sc.Instance.create(null, scSymbol);
    defer instance.destroy();

    const adapters = try instance.enumerateAdaptersAlloc(arena);
    if (adapters.len == 0) return error.NoAdapter;
    const adapter = for (adapters) |adapter| {
        if (instance.adapterInfo(adapter).kind == .discrete_gpu) break adapter;
    } else adapters[0];
    std.log.info("selected device: {s}", .{std.mem.sliceTo(&instance.adapterInfo(adapter).name, 0)});

    const device = instance.createDevice(adapter);
    defer device.destroy();

    const gpu_gpa = sc.heap.rawDeviceAllocator(device);
    var fixed_buffer_allocator: sc.heap.FixedBufferAllocator = try .initAlloc(gpu_gpa, .initFill(1024 * 1024 * 64));
    defer fixed_buffer_allocator.deinit(gpu_gpa);
    const gpu_arena = fixed_buffer_allocator.allocator();

    const queue = device.getQueue(.graphics);

    const surface = try common.createSurface(device, window);
    defer surface.destroy();

    if (!surface.supportedUsage().storage) return error.SurfaceStorageUnsupported;
    const swapchain_format = for (try surface.supportedFormatsAlloc(arena)) |format| {
        if (format == .rgba8_unorm or format == .bgra8_unorm) break format;
    } else return error.NoSupportedSurfaceFormat;

    const swapchain: *sc.Swapchain = try .create(queue, surface, .{
        .format = swapchain_format,
        .usage = .{ .storage = true },
        .present_mode = .fifo,
        .frame_latency_max = 1,
    });
    defer swapchain.destroy();

    const frame_timeline = try device.createTimeline(0);
    defer frame_timeline.destroy();

    const descriptor_size_and_align = device.descriptorSizeAndHeapAlign();

    const pipeline = try device.createComputePipeline(@embedFile("generate_texture.scir"));
    defer pipeline.destroy();

    var renderer: Renderer = .{
        .io = io,
        .window = window,
        .device = device,
        .queue = queue,
        .swapchain = swapchain,
        .frame_timeline = frame_timeline,
        .frame_index = 1,
        .descriptor_heap = try gpu_arena.runtimeAlignedAlloc(
            u8,
            descriptor_size_and_align.alignment(),
            descriptor_size_and_align.size * descriptor_count_max,
            .upload,
        ),
        .data_maps = undefined,
        .pipeline = pipeline,
        .start = .now(io, .awake),
    };
    for (&renderer.data_maps) |*data_map| data_map.* = try gpu_arena.create(Data, .upload);
    defer if (renderer.frame_index > 1) renderer.frame_timeline.wait(renderer.frame_index - 1) catch {};

    if (!c.SDL_AddEventWatch(drawFrameOnExpose, &renderer)) return error.SdlAddEventWatch;
    defer c.SDL_RemoveEventWatch(drawFrameOnExpose, &renderer);

    var quit = false;
    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event)) quit = quit or event.type == c.SDL_EVENT_QUIT;
        try drawFrame(&renderer);
    }
}

fn drawFrameOnExpose(userdata: ?*anyopaque, event: [*c]c.SDL_Event) callconv(.c) bool {
    if (event.*.type == c.SDL_EVENT_WINDOW_EXPOSED)
        drawFrame(@ptrCast(@alignCast(userdata))) catch |err| std.debug.panic("drawFrame failed: {t}", .{err});
    return true;
}

fn drawFrame(renderer: *Renderer) !void {
    const frame_index = renderer.frame_index;
    if (frame_index > frames_in_flight) try renderer.frame_timeline.wait(frame_index - frames_in_flight);

    var width: c_int = undefined;
    var height: c_int = undefined;
    if (!c.SDL_GetWindowSizeInPixels(renderer.window, &width, &height)) return error.SdlGetWindowSizeInPixels;
    const back_buffer = renderer.swapchain.acquireBackBuffer(.{ .width = @intCast(width), .height = @intCast(height) }) catch |err| switch (err) {
        error.NoBackbuffer => return c.SDL_Delay(16), // minimized
        else => |e| return e,
    };

    const slot: u32 = @intCast(frame_index % frames_in_flight);

    const time_ns: f64 = @floatFromInt(renderer.start.untilNow(renderer.io, .awake).nanoseconds);
    const data_map = renderer.data_maps[slot];
    data_map.host.* = .{
        .output_texture = slot,
        .time = @floatCast(time_ns / std.time.ns_per_s),
    };

    const descriptor = try back_buffer.texture.storageDescriptor(.{});
    renderer.device.storeDescriptor(&descriptor, renderer.descriptor_heap.host_ptr, slot);

    const command_buffer = try renderer.queue.startCommandRecording();
    command_buffer.setActiveTextureHeap(renderer.descriptor_heap.device_ptr);
    command_buffer.setPipeline(renderer.pipeline);
    command_buffer.dispatch(
        .as(data_map.device),
        (back_buffer.extent.width + workgroup_size - 1) / workgroup_size,
        (back_buffer.extent.height + workgroup_size - 1) / workgroup_size,
        1,
    );
    try renderer.queue.submitAndSignal(&.{command_buffer}, .{ .timeline = renderer.frame_timeline, .value = frame_index });
    try renderer.swapchain.present();

    renderer.frame_index += 1;
}
