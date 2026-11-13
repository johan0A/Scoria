const std = @import("std");
const sc = @import("scoria");
const c = @import("c");
const common = @import("common");

const scSymbol = @extern(sc.Symbol, .{ .name = "scSymbol" });

const frames_in_flight = 2;
const vertex_count = 3;

const Data = extern struct {
    positions: sc.Ptr(.many, [3]f32, .{}),
    colors: sc.Ptr(.many, [3]f32, .{}),
};

const Renderer = struct {
    window: *c.SDL_Window,
    queue: *sc.Queue,
    swapchain: *sc.Swapchain,
    frame_timeline: *sc.Timeline,
    command_pools: [frames_in_flight]*sc.CommandPool,
    frame_index: u64,
    data: sc.Ptr(.one, Data, .{}),
    pipeline: *sc.Pipeline,
};

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();

    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) return error.SdlInit;
    defer c.SDL_Quit();

    const window = c.SDL_CreateWindow("hello-triangle", 512, 512, c.SDL_WINDOW_VULKAN | c.SDL_WINDOW_RESIZABLE) orelse return error.SdlCreateWindow;
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
    var fixed_buffer_allocator: sc.heap.FixedBufferAllocator = try .initAlloc(gpu_gpa, .initFill(1024 * 1024));
    defer fixed_buffer_allocator.deinit(gpu_gpa);
    const gpu_arena = fixed_buffer_allocator.allocator();

    const queue = device.getQueue(.graphics);

    const surface = try common.createSurface(device, window);
    defer surface.destroy();

    if (!surface.supportedUsage().color_attachment) return error.SurfaceColorAttachmentUnsupported;
    const swapchain_format = for (try surface.supportedFormatsAlloc(.srgb_nonlinear, arena)) |format| {
        if (format == .rgba8_unorm_srgb or format == .bgra8_unorm_srgb) break format;
    } else return error.NoSupportedSurfaceFormat;

    const swapchain: *sc.Swapchain = try .create(queue, surface, .{
        .format = swapchain_format,
        .usage = .{ .color_attachment = true },
        .present_mode = .fifo,
        .frame_latency_max = 1,
    });
    defer swapchain.destroy();

    const frame_timeline = try device.createTimeline(0);
    defer frame_timeline.destroy();

    var command_pools: [frames_in_flight]*sc.CommandPool = undefined;
    var command_pool_count: usize = 0;
    defer for (command_pools[0..command_pool_count]) |command_pool| command_pool.destroy();
    for (&command_pools) |*command_pool| {
        command_pool.* = try queue.createCommandPool();
        command_pool_count += 1;
    }

    const positions_map = try gpu_arena.create([vertex_count][3]f32, .upload);
    positions_map.host.* = .{
        .{ -1, 1, 0 },
        .{ 0, -1, 0 },
        .{ 1, 1, 0 },
    };

    const colors_map = try gpu_arena.create([vertex_count][3]f32, .upload);
    colors_map.host.* = .{
        .{ 0, 0, 1 },
        .{ 0, 1, 0 },
        .{ 1, 0, 0 },
    };

    const data_map = try gpu_arena.create(Data, .upload);
    data_map.host.* = .{
        .positions = .ptrCast(positions_map.device),
        .colors = .ptrCast(colors_map.device),
    };

    const pipeline = try device.createGraphicsPipeline(@embedFile("vert.scir"), @embedFile("frag.scir"), .{
        .color_target_count = 1,
        .color_targets = &.{.{ .format = swapchain_format }},
    });
    defer pipeline.destroy();

    var renderer: Renderer = .{
        .window = window,
        .queue = queue,
        .swapchain = swapchain,
        .frame_timeline = frame_timeline,
        .command_pools = command_pools,
        .frame_index = 1,
        .data = data_map.device,
        .pipeline = pipeline,
    };
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

    const command_pool = renderer.command_pools[frame_index % frames_in_flight];
    try command_pool.reset();
    const command_buffer = try command_pool.startCommandRecording();
    command_buffer.beginRenderPass(.{
        .color_attachment_count = 1,
        .color_attachments = &.{.{ .texture = back_buffer.texture, .load_op = .clear }},
    });
    command_buffer.setPipeline(renderer.pipeline);
    command_buffer.draw(.as(renderer.data), .as(renderer.data), vertex_count, 1);
    command_buffer.endRenderPass();
    try renderer.queue.submitAndSignal(&.{command_buffer}, &.{}, .{ .timeline = renderer.frame_timeline, .value = frame_index });
    try renderer.swapchain.present();

    renderer.frame_index += 1;
}
