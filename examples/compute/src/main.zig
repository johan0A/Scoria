const std = @import("std");
const target = @import("builtin").target;
const sc = @import("scoria");
const c = @import("c");

const scSymbol = @extern(sc.Symbol, .{ .name = "scSymbol" });

const Data = extern struct {
    output_texture: u32,
    time: f32,
};

const frames_in_fligt = 2;
const workgroup_size = 8;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();

    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) @panic("SDL_Init failed");
    defer c.SDL_Quit();

    var surface_extent: sc.Extent2D = .{ .width = 512, .height = 512 };

    const window = c.SDL_CreateWindow(
        "title",
        @intCast(surface_extent.width),
        @intCast(surface_extent.height),
        c.SDL_WINDOW_VULKAN | c.SDL_WINDOW_RESIZABLE,
    ) orelse @panic("SDL_CreateWindow failed");
    defer c.SDL_DestroyWindow(window);

    const instance = sc.Instance.create(null, scSymbol);
    defer instance.destroy();

    const adapters = try instance.enumerateAdaptersAlloc(arena);
    if (adapters.len == 0) return error.NoAdapter;
    const adapter = for (adapters) |adapter| {
        if (instance.adapterInfo(adapter).kind == .discrete_gpu) break adapter;
    } else adapters[0];
    const adapter_info = instance.adapterInfo(adapter);
    std.log.info("selected device: {s}", .{std.mem.sliceTo(&adapter_info.name, 0)});

    const device = instance.createDevice(adapter);
    defer device.destroy();

    const gpu_gpa = sc.heap.rawDeviceAllocator(device);
    var fix_buffer_allocator: sc.heap.FixedBufferAllocator = try .initAlloc(gpu_gpa, .initFill(1024 * 1024 * 64));
    defer fix_buffer_allocator.deinit(gpu_gpa);
    const gpu_arena = fix_buffer_allocator.allocator();

    const queue = device.getQueue(.graphics);

    const props = c.SDL_GetWindowProperties(window);
    const surface = switch (target.os.tag) {
        .windows => blk: {
            const hwnd = c.SDL_GetPointerProperty(props, c.SDL_PROP_WINDOW_WIN32_HWND_POINTER, null) orelse @panic("TODO");
            const hinstance = c.SDL_GetPointerProperty(props, c.SDL_PROP_WINDOW_WIN32_INSTANCE_POINTER, null) orelse @panic("TODO");
            const surface_desc: sc.SurfaceWin32Desc = .{ .hinstance = hinstance, .hwnd = hwnd };
            break :blk sc.Surface.createWin32(device, surface_desc);
        },
        else => blk: {
            const display = c.SDL_GetPointerProperty(props, c.SDL_PROP_WINDOW_X11_DISPLAY_POINTER, null) orelse @panic("TODO");
            const x11_window = c.SDL_GetNumberProperty(props, c.SDL_PROP_WINDOW_X11_WINDOW_NUMBER, 0);
            if (x11_window == 0) @panic("TODO");
            const surface_desc: sc.SurfaceXlibDesc = .{ .display = display, .window = @intCast(x11_window) };
            break :blk sc.Surface.createXlib(device, surface_desc);
        },
    };
    defer surface.destroy();

    const surface_formats = try surface.supportedFormatsAlloc(arena);
    const swapchain_format = for (surface_formats) |f| {
        if (f == .rgba8_unorm or f == .bgra8_unorm) break f;
    } else return error.NoSupportedSurfaceFormat;

    const surface_usage = surface.supportedUsage();
    if (!surface_usage.storage) return error.SurfaceStorageUnsupported;

    const frame_semaphore = try device.createSemaphore(0);
    defer frame_semaphore.destroy();
    var frame_index: u64 = 1;

    const swapchain: *sc.Swapchain = try .create(queue, surface, .{
        .format = swapchain_format,
        .usage = .{ .storage = true },
        .present_mode = .fifo,
        .frame_latency_max = 1,
    });
    defer swapchain.destroy();

    const descriptor_size_and_align = device.descriptorSizeAndHeapAlign();
    const descriptor_heap = try gpu_arena.runtimeAlignedAlloc(
        u8,
        descriptor_size_and_align.alignment(),
        descriptor_size_and_align.size * 65536,
        .upload,
    );

    var data_maps: [frames_in_fligt]@TypeOf(try gpu_arena.create(Data, .upload)) = undefined;
    for (&data_maps) |*d| d.* = try gpu_arena.create(Data, .upload);

    const pipeline = try device.createComputePipeline(@embedFile("generate_texture.scir"));
    defer pipeline.destroy();

    const start: std.Io.Timestamp = .now(io, .real);

    var quit = false;
    while (!quit) {
        if (frame_index > frames_in_fligt)
            try frame_semaphore.wait(frame_index - frames_in_fligt);

        const back_buffer_maybe = swapchain.acquireBackBuffer(surface_extent) catch |err| switch (err) {
            error.NoBackbuffer => null,
            else => |e| return e,
        };

        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event)) switch (event.type) {
            c.SDL_EVENT_QUIT => quit = true,
            else => {},
        };
        var c_extent: [2]c_int = undefined;
        if (!c.SDL_GetWindowSizeInPixels(window, &c_extent[0], &c_extent[1])) @panic("SDL_GetWindowSizeInPixels failed");
        surface_extent = .{ .width = @intCast(c_extent[0]), .height = @intCast(c_extent[1]) };

        const back_buffer = back_buffer_maybe orelse {
            c.SDL_Delay(16);
            continue;
        };

        const slot: u32 = @intCast(frame_index % frames_in_fligt);

        const elapsed_us: f64 = @floatFromInt(start.untilNow(io, .real).nanoseconds);
        const data_map = data_maps[slot];
        data_map.host.* = .{
            .output_texture = slot,
            .time = @floatCast(elapsed_us / 1e9),
        };

        const descriptor = try back_buffer.texture.storageDescriptor(.{});
        device.storeDescriptor(&descriptor, descriptor_heap.host_ptr, slot);

        const command_buffer = try queue.startCommandRecording();
        command_buffer.setActiveTextureHeap(descriptor_heap.device_ptr);
        command_buffer.setPipeline(pipeline);
        command_buffer.dispatch(
            .as(data_map.device),
            (back_buffer.extent.width + workgroup_size - 1) / workgroup_size,
            (back_buffer.extent.height + workgroup_size - 1) / workgroup_size,
            1,
        );
        try queue.submitAndSignal(&.{command_buffer}, frame_semaphore, frame_index);
        try swapchain.present();

        frame_index += 1;
    }

    if (frame_index > 1) try frame_semaphore.wait(frame_index - 1);
}
