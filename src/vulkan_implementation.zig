const std = @import("std");
const build_options = @import("options");
const sf = @import("sf_minimal.zig");
const to_sf = @import("bridge.zig").to_sf;
const to_vk = @import("bridge.zig").to_vk;
const sfir = @import("sfir.zig");
const vk = @import("vulkan");
const VulkanLoader = @import("VulkanLoader.zig");
const symbol_map = @import("driver_symbol_map.zig");

pub const Instance = struct {
    handle: vk.InstanceProxy,
    loader: VulkanLoader,
    surface_support: SurfaceSupport,
    debug_messenger: vk.DebugUtilsMessengerEXT,
    sf_gpa: sf.HostAllocator,
    gpa: std.mem.Allocator,

    devices: std.heap.MemoryPool(Object(Device)),

    const SurfaceSupport = packed struct {
        surface: bool = false,
        xlib: bool = false,
        win32: bool = false,
    };

    pub fn create(
        host_allocator: ?*sf.HostAllocator,
    ) *Object(Instance) {
        return createInner(host_allocator) catch |err| switch (err) {
            error.OutOfMemory,
            error.OutOfHostMemory,
            error.OutOfDeviceMemory,
            error.Unknown,
            error.InitializationFailed,
            error.ExtensionNotPresent,
            error.VulkanLoaderNotFound,
            error.LayerNotPresent,
            error.IncompatibleDriver,
            => @panic("TODO"),
        };
    }
    fn createInner(
        host_allocator: ?*sf.HostAllocator,
    ) !*Object(Instance) {
        const gpa: std.mem.Allocator = if (host_allocator) |ha| .{
            .ptr = @ptrCast(@alignCast(ha)),
            .vtable = wrap_sf_allocator.vtable,
        } else std.heap.smp_allocator;

        var arena_impl: std.heap.ArenaAllocator = .init(gpa);
        defer arena_impl.deinit();
        const arena = arena_impl.allocator();

        const loader: VulkanLoader = try .open();

        const base_dispatch: vk.BaseWrapper = .load(loader.proc);

        var extensions: std.ArrayList([*:0]const u8) = .empty;
        try extensions.append(arena, vk.instance_extensions.ext_debug_utils.name.ptr);

        var surface_support: SurfaceSupport = .{};

        const available_extensions = try base_dispatch.enumerateInstanceExtensionPropertiesAlloc(null, arena);
        for (available_extensions) |available_extension| {
            const available_ext_name = std.mem.sliceTo(&available_extension.extension_name, 0);

            const surface = vk.instance_extensions.khr_surface.name;
            if (std.mem.eql(u8, available_ext_name, surface)) {
                surface_support.surface = true;
                try extensions.append(arena, surface);
            }

            const win32 = vk.instance_extensions.khr_win_32_surface.name;
            if (std.mem.eql(u8, available_ext_name, win32)) {
                surface_support.win32 = true;
                try extensions.append(arena, win32);
            }

            const xlib = vk.instance_extensions.khr_xlib_surface.name;
            if (std.mem.eql(u8, available_ext_name, xlib)) {
                surface_support.xlib = true;
                try extensions.append(arena, xlib);
            }
        }

        const validation_layer = "VK_LAYER_KHRONOS_validation";
        var enable_validation_layers = build_options.validation_layers;

        if (enable_validation_layers) {
            const available_layers = try base_dispatch.enumerateInstanceLayerPropertiesAlloc(arena);
            for (available_layers) |available_layer| {
                if (std.mem.eql(u8, std.mem.sliceTo(&available_layer.layer_name, 0), validation_layer)) break;
            } else {
                std.log.warn("vulkan validation layers unsupported", .{});
                enable_validation_layers = false;
            }
        }

        const create_info: vk.InstanceCreateInfo = .{
            .p_application_info = &.{
                .application_version = 0,
                .engine_version = 0,
                .api_version = vk.makeApiVersion(1, 3, 0, 0).toU32(),
            },
            .enabled_extension_count = @intCast(extensions.items.len),
            .pp_enabled_extension_names = extensions.items.ptr,
            .pp_enabled_layer_names = if (enable_validation_layers) &.{validation_layer} else null,
            .enabled_layer_count = if (enable_validation_layers) 1 else 0,
        };
        const instance_handle = try base_dispatch.createInstance(&create_info, null);

        const instance_dispatch = try gpa.create(vk.InstanceWrapper);
        instance_dispatch.* = .load(instance_handle, base_dispatch.dispatch.vkGetInstanceProcAddr.?);
        const handle: vk.InstanceProxy = .init(instance_handle, instance_dispatch);

        const debug_messenger_info: vk.DebugUtilsMessengerCreateInfoEXT = .{
            .message_severity = .{ .warning_ext = true, .error_ext = true },
            .message_type = .{ .general_ext = true, .validation_ext = true, .performance_ext = true },
            .pfn_user_callback = debugCallback,
        };
        const debug_messenger = try handle.createDebugUtilsMessengerEXT(&debug_messenger_info, null);

        const instance = try gpa.create(Object(Instance));
        instance.set(undefined, .{
            .handle = handle,
            .loader = loader,
            .surface_support = surface_support,
            .debug_messenger = debug_messenger,
            .sf_gpa = if (host_allocator) |ha| ha.* else undefined,
            .gpa = if (host_allocator) |ha| .{
                .ptr = @ptrCast(@alignCast(ha)),
                .vtable = wrap_sf_allocator.vtable,
            } else std.heap.smp_allocator,
            .devices = .empty,
        });
        return instance;
    }

    pub fn destroyInstance(instance_obj: *Object(Instance)) void {
        const instance = instance_obj.body();
        instance.handle.destroyDebugUtilsMessengerEXT(instance.debug_messenger, null);
        instance.handle.destroyInstance(null);
        instance.loader.close();
        instance.gpa.destroy(instance.handle.wrapper);
        instance.gpa.destroy(instance_obj);
    }

    pub fn enumerateAdapters(
        instance: *Object(Instance),
        adapters_buffer_size: usize,
        adapters_buffer: ?[*]*Adapter,
        adapters_count: *usize,
    ) void {
        enumerateAdaptersInner(instance.body(), if (adapters_buffer) |buf| buf[0..adapters_buffer_size] else null, adapters_count) catch |err| switch (err) {
            error.OutOfMemory,
            error.OutOfHostMemory,
            error.OutOfDeviceMemory,
            error.Unknown,
            error.InitializationFailed,
            => @panic("TODO"),
        };
    }
    fn enumerateAdaptersInner(
        instance: *Instance,
        adapters_buffer_opt: ?[]*Adapter,
        adapters_count: *usize,
    ) !void {
        // TODO: filter incompatible devices
        const physical_devices = try instance.handle.enumeratePhysicalDevicesAlloc(instance.gpa);
        defer instance.gpa.free(physical_devices);
        adapters_count.* = physical_devices.len;
        errdefer adapters_count.* = 0;
        const adapters_buffer = adapters_buffer_opt orelse return;
        for (0..@min(adapters_buffer.len, physical_devices.len)) |i| {
            adapters_buffer[i] = .fromPhysicalDevice(physical_devices[i]);
        }
    }

    pub fn adapterInfo(instance: *Object(Instance), adapter: *Adapter) sf.AdapterInfo {
        return adapterInfoInner(instance.body(), adapter);
    }
    pub fn adapterInfoInner(instance: *Instance, adapter: *Adapter) sf.AdapterInfo {
        const physical_device = adapter.asPhysicalDevice();
        const properties = instance.handle.getPhysicalDeviceProperties(physical_device);
        return .{
            .name = properties.device_name,
            .kind = to_sf.adapterKind(properties.device_type),
        };
    }
};

pub const Surface = struct {
    handle: vk.SurfaceKHR,
    d: *Device,

    pub fn createSurfaceWin32(d: *Object(Device), desc: sf.SurfaceWin32Desc) *Object(Surface) {
        return createWin32Inner(d.body(), desc) catch |err| switch (err) {
            error.OutOfMemory,
            error.OutOfHostMemory,
            error.OutOfDeviceMemory,
            error.Unknown,
            => @panic("TODO"),
        };
    }
    fn createWin32Inner(d: *Device, desc: sf.SurfaceWin32Desc) !*Object(Surface) {
        const info: vk.Win32SurfaceCreateInfoKHR = .{ .hinstance = @ptrCast(desc.hinstance), .hwnd = @ptrCast(desc.hwnd) };
        const surface = try d.surfaces.create(d.gpa);
        surface.set(d.table, .{ .handle = try d.instance.handle.createWin32SurfaceKHR(&info, null), .d = d });
        return surface;
    }

    pub fn createSurfaceXlib(device: *Object(Device), desc: sf.SurfaceXlibDesc) *Object(Surface) {
        return createXlibInner(device.body(), desc) catch |err| switch (err) {
            error.OutOfMemory,
            error.OutOfHostMemory,
            error.OutOfDeviceMemory,
            error.Unknown,
            => @panic("TODO"),
        };
    }
    fn createXlibInner(d: *Device, desc: sf.SurfaceXlibDesc) !*Object(Surface) {
        const info: vk.XlibSurfaceCreateInfoKHR = .{ .dpy = @ptrCast(desc.display), .window = @intCast(desc.window) };
        const surface = try d.surfaces.create(d.gpa);
        surface.set(d.table, .{ .handle = try d.instance.handle.createXlibSurfaceKHR(&info, null), .d = d });
        return surface;
    }

    pub fn destroy(surface: *Object(Surface)) void {
        destroyInner(surface.body());
    }
    fn destroyInner(surface: *Surface) void {
        surface.d.instance.handle.destroySurfaceKHR(surface.handle, null);
        surface.d.gpa.destroy(surface);
    }
};

pub const Adapter = opaque {
    comptime {
        std.debug.assert(@sizeOf(vk.PhysicalDevice) == @sizeOf(*Adapter));
    }
    fn asPhysicalDevice(adapter: *Adapter) vk.PhysicalDevice {
        return @ptrCast(adapter);
    }
    fn fromPhysicalDevice(physical_device: vk.PhysicalDevice) *Adapter {
        return @ptrCast(physical_device);
    }
};

pub const Device = struct {
    handle: vk.DeviceProxy,
    instance: *Instance,
    physical_device: vk.PhysicalDevice,

    queue_states: [max_queue_state_count]QueueState,
    queue_state_count: u8,
    queue_id_from_type: std.EnumArray(sf.QueueKind, QueueId),
    queues: std.EnumArray(sf.QueueKind, Object(Queue)),

    gpa: std.mem.Allocator,

    heap: AddressMap,

    descriptor_buffer_properties: ?vk.PhysicalDeviceDescriptorBufferPropertiesEXT,

    texture_heap_set_layout: vk.DescriptorSetLayout,

    pending_texture_inits: std.array_hash_map.Auto(vk.Image, sf.TextureDesc),
    texture_init_timeline: struct {
        semaphore: Semaphore,
        value: u64,
    },

    memory_properties: vk.PhysicalDeviceMemoryProperties,
    has_host_visible_device_local: bool,

    surfaces: std.heap.MemoryPool(Object(Surface)),
    semaphores: std.heap.MemoryPool(Object(Semaphore)),
    swapchains: std.heap.MemoryPool(Object(Swapchain)),
    command_buffers: std.heap.MemoryPool(Object(CommandBuffer)),
    textures: std.heap.MemoryPool(Object(Texture)),
    pipelines: std.heap.MemoryPool(Object(Pipeline)),
    depth_stencil_states: std.heap.MemoryPool(Object(DepthStencilState)),

    table: *anyopaque,

    const max_queue_state_count = @typeInfo(sf.QueueKind).@"enum".field_names.len;

    const QueueId = enum(u8) { _ };

    const QueueState = struct {
        queue: vk.Queue,
        family: u32,

        timeline: Semaphore,
        last_submitted: u64,

        command_pool: vk.CommandPool,
        pending_command_buffers: std.ArrayList(PendingCommandBuffer),
        free_command_buffers: std.ArrayList(vk.CommandBuffer),

        const PendingCommandBuffer = struct {
            value: u64,
            command_buffer: vk.CommandBuffer,
        };
    };

    const AddressMap = struct {
        entries: std.ArrayList(Entry),

        const Entry = struct {
            buffer: vk.Buffer,
            memory: vk.DeviceMemory,
            size: usize,
            device_addr: sf.DeviceAddress,
            host_addr: ?usize,

            fn destroy(entry: *Entry, d: Device) void {
                d.handle.destroyBuffer(entry.buffer, null);
                d.handle.freeMemory(entry.memory, null);
                entry.* = undefined;
            }
        };

        fn entryAndOffsetFromAddr(map: *const AddressMap, device_addr: sf.DeviceAddress) struct { Entry, vk.DeviceSize } {
            const entry = map.entryFromAddr(device_addr);
            const offset = device_addr - entry.device_addr;
            return .{ entry, @intCast(offset) };
        }

        fn entryFromAddr(map: *const AddressMap, device_addr: sf.DeviceAddress) Entry {
            return map.entries.items[map.indexFromAddr(device_addr)];
        }

        fn indexFromAddr(map: *const AddressMap, device_addr: sf.DeviceAddress) usize {
            return std.sort.upperBound(
                Entry,
                map.entries.items,
                device_addr,
                order,
            ) - 1;
        }

        fn insert(
            map: *AddressMap,
            gpa: std.mem.Allocator,
            entry: Entry,
        ) !void {
            const insert_index = std.sort.upperBound(
                Entry,
                map.entries.items,
                entry.device_addr,
                order,
            );
            try map.entries.insert(gpa, insert_index, entry);
        }

        fn order(addr: usize, item: Entry) std.math.Order {
            return std.math.order(addr, item.device_addr);
        }
    };

    pub fn create(instance: *Object(Instance), adapter: *Adapter) *Object(Device) {
        return createInner(
            instance.body(),
            instance.header,
            adapter,
        ) catch |err| switch (err) {
            error.OutOfMemory,
            error.OutOfHostMemory,
            error.OutOfDeviceMemory,
            error.DeviceLost,
            error.Unknown,
            error.InitializationFailed,
            error.ExtensionNotPresent,
            error.FeatureNotPresent,
            error.TooManyObjects,
            => @panic("TODO"),
        };
    }
    fn createInner(
        instance: *Instance,
        table: *anyopaque,
        adapter: *Adapter,
    ) !*Object(Device) {
        var arena_impl: std.heap.ArenaAllocator = .init(instance.gpa);
        defer arena_impl.deinit();
        const arena = arena_impl.allocator();

        const device_handle = try createLogicalDevice(
            arena,
            adapter.asPhysicalDevice(),
            instance.handle.wrapper,
            instance.surface_support.surface,
        );
        const device_dispatch = try instance.gpa.create(vk.DeviceWrapper);
        device_dispatch.* = .load(device_handle, instance.handle.wrapper.dispatch.vkGetDeviceProcAddr.?);
        const handle: vk.DeviceProxy = .init(device_handle, device_dispatch);

        var bindings = [_]vk.DescriptorSetLayoutBinding{.{
            .binding = 0,
            .descriptor_type = .mutable_ext,
            .descriptor_count = 0,
            .stage_flags = .{ .vertex = true, .fragment = true, .compute = true },
            .p_immutable_samplers = null,
        }};
        const allowed_types: []const vk.DescriptorType = &.{ .storage_image, .sampled_image };
        const mutable_type_list: vk.MutableDescriptorTypeListEXT = .{
            .descriptor_type_count = allowed_types.len,
            .p_descriptor_types = allowed_types.ptr,
        };
        const mutable_info: vk.MutableDescriptorTypeCreateInfoEXT = .{
            .mutable_descriptor_type_list_count = 1,
            .p_mutable_descriptor_type_lists = &.{mutable_type_list},
        };
        const binding_flags: vk.DescriptorBindingFlags = .{
            .partially_bound = true,
            .variable_descriptor_count = true,
        };
        const binding_flags_info: vk.DescriptorSetLayoutBindingFlagsCreateInfo = .{
            .p_next = &mutable_info,
            .binding_count = 1,
            .p_binding_flags = &.{binding_flags},
        };
        const layout_info: vk.DescriptorSetLayoutCreateInfo = .{
            .p_next = &binding_flags_info,
            .flags = .{ .descriptor_buffer_ext = true },
            .binding_count = 1,
            .p_bindings = &bindings,
        };
        var variable_support: vk.DescriptorSetVariableDescriptorCountLayoutSupport = .{ .max_variable_descriptor_count = 0 };
        var layout_support: vk.DescriptorSetLayoutSupport = .{ .p_next = &variable_support, .supported = .false };
        handle.getDescriptorSetLayoutSupport(&layout_info, &layout_support);
        bindings[0].descriptor_count = variable_support.max_variable_descriptor_count;
        const descriptor_set_layout = try handle.createDescriptorSetLayout(&layout_info, null);

        const queue_family_indices = try findQueueFamilies(arena, adapter.asPhysicalDevice(), instance.handle.wrapper);

        var queue_states: [max_queue_state_count]QueueState = undefined;
        var queue_state_count: u8 = 0;
        var queue_of_type: std.EnumArray(sf.QueueKind, QueueId) = .initUndefined();

        for (std.enums.values(sf.QueueKind)) |queue_kind| {
            const family_index = queue_family_indices.get(queue_kind);
            const existing: ?QueueId = for (queue_states[0..queue_state_count], 0..) |q, i| {
                if (q.family == family_index) break @fromBackingInt(@intCast(i));
            } else null;
            queue_of_type.set(queue_kind, existing orelse blk: {
                const timeline: Semaphore = try .createVkDevice(handle, 0);
                const command_pool_info: vk.CommandPoolCreateInfo = .{
                    .flags = .{ .transient = true, .reset_command_buffer = true },
                    .queue_family_index = family_index,
                };
                const pool = try handle.createCommandPool(&command_pool_info, null);

                queue_states[queue_state_count] = .{
                    .queue = handle.getDeviceQueue(family_index, 0),
                    .family = family_index,
                    .timeline = timeline,
                    .last_submitted = 0,
                    .command_pool = pool,
                    .pending_command_buffers = .empty,
                    .free_command_buffers = .empty,
                };
                queue_state_count += 1;
                break :blk @fromBackingInt(queue_state_count - 1);
            });
        }

        const memory_properties = instance.handle.getPhysicalDeviceMemoryProperties(adapter.asPhysicalDevice());

        const has_host_visible_device_local = for (0..memory_properties.memory_type_count) |i| {
            const t = memory_properties.memory_types[i];
            if (t.property_flags.device_local and t.property_flags.host_visible) {
                const memory_heap = memory_properties.memory_heaps[t.heap_index];
                if (memory_heap.size > 256 * 1024 * 1024) break true;
            }
        } else false;

        const device = try instance.gpa.create(Object(Device));
        device.set(table, .{
            .handle = handle,
            .instance = instance,
            .physical_device = adapter.asPhysicalDevice(),

            .queue_states = queue_states,
            .queue_state_count = queue_state_count,
            .queue_id_from_type = queue_of_type,
            .queues = .initUndefined(),

            .gpa = instance.gpa,
            .heap = .{ .entries = .empty },
            .descriptor_buffer_properties = null,
            .texture_heap_set_layout = descriptor_set_layout,

            .pending_texture_inits = .empty,
            .texture_init_timeline = .{
                .value = 0,
                .semaphore = try .createVkDevice(handle, 0),
            },

            .memory_properties = memory_properties,
            .has_host_visible_device_local = has_host_visible_device_local,

            .surfaces = .empty,
            .semaphores = .empty,
            .swapchains = .empty,
            .command_buffers = .empty,
            .textures = .empty,
            .pipelines = .empty,
            .depth_stencil_states = .empty,

            .table = table,
        });
        return device;
    }
    fn createLogicalDevice(
        arena: std.mem.Allocator,
        physical_device: vk.PhysicalDevice,
        instance_dispatch: *const vk.InstanceWrapper,
        surface_support: bool,
    ) !vk.Device {
        var queue_family_count: u32 = undefined;
        instance_dispatch.getPhysicalDeviceQueueFamilyProperties(physical_device, &queue_family_count, null);

        const queue_infos = try arena.alloc(vk.DeviceQueueCreateInfo, queue_family_count);
        for (queue_infos, 0..) |*queue_info, i| {
            queue_info.* = .{
                .queue_family_index = @intCast(i),
                .queue_count = 1,
                .p_queue_priorities = &.{1},
            };
        }

        var mutable_descriptor_features: vk.PhysicalDeviceMutableDescriptorTypeFeaturesEXT = .{
            .mutable_descriptor_type = .true,
        };
        var descriptor_buffer_features: vk.PhysicalDeviceDescriptorBufferFeaturesEXT = .{
            .p_next = &mutable_descriptor_features,
            .descriptor_buffer = .true,
        };
        var device_features_vk13: vk.PhysicalDeviceVulkan13Features = .{
            .p_next = &descriptor_buffer_features,
            .dynamic_rendering = .true,
            .synchronization_2 = .true,
        };
        var device_features_vk12: vk.PhysicalDeviceVulkan12Features = .{
            .p_next = &device_features_vk13,
            .buffer_device_address = .true,
            .runtime_descriptor_array = .true,
            .descriptor_binding_partially_bound = .true,
            .descriptor_binding_variable_descriptor_count = .true,
            .descriptor_binding_sampled_image_update_after_bind = .true,
            .descriptor_binding_storage_buffer_update_after_bind = .true,
            .scalar_block_layout = .true,
            .timeline_semaphore = .true,
            .shader_float_16 = .true,
            .shader_int_8 = .true,
            .storage_buffer_8_bit_access = .true,
            .uniform_and_storage_buffer_8_bit_access = .true,
        };
        const device_features_vk11: vk.PhysicalDeviceVulkan11Features = .{
            .p_next = &device_features_vk12,
            .shader_draw_parameters = .true,
            .storage_buffer_16_bit_access = .true,
            .uniform_and_storage_buffer_16_bit_access = .true,
        };

        var required_device_extensions_buff: [64][*:0]const u8 = undefined;
        var required_device_extensions: std.ArrayList([*:0]const u8) = .initBuffer(&required_device_extensions_buff);
        required_device_extensions.appendSliceAssumeCapacity(&.{
            vk.device_extensions.ext_descriptor_buffer.name,
            vk.device_extensions.ext_mutable_descriptor_type.name,
            // vk.device_extensions.khr_unified_image_layouts.name, TODO
        });
        if (surface_support) required_device_extensions.appendAssumeCapacity(
            vk.device_extensions.khr_swapchain.name,
        );

        return try instance_dispatch.createDevice(physical_device, &.{
            .p_next = &device_features_vk11,
            .p_queue_create_infos = queue_infos.ptr,
            .queue_create_info_count = @intCast(queue_infos.len),
            .pp_enabled_extension_names = required_device_extensions.items.ptr,
            .enabled_extension_count = @intCast(required_device_extensions.items.len),
            .p_enabled_features = &.{
                .shader_int_64 = .true,
                .shader_int_16 = .true,
                .sampler_anisotropy = .true,
                .multi_draw_indirect = .true,
                // .robust_buffer_access = .true, TODO: consider
            },
        }, null);
    }
    fn findQueueFamilies(
        arena: std.mem.Allocator,
        physical_device: vk.PhysicalDevice,
        instance_dispatch: *const vk.InstanceWrapper,
    ) !std.EnumArray(sf.QueueKind, u32) {
        const queue_family_indices = try instance_dispatch.getPhysicalDeviceQueueFamilyPropertiesAlloc(physical_device, arena);

        var graphics: u32 = std.math.maxInt(u32);
        for (queue_family_indices, 0..) |family, i| {
            if (family.queue_flags.graphics) {
                graphics = @intCast(i);
                break;
            }
        }

        var compute = graphics;
        for (queue_family_indices, 0..) |family, i| {
            if (family.queue_flags.compute and !family.queue_flags.graphics) {
                compute = @intCast(i);
                break;
            }
        }

        var transfer = compute;
        for (queue_family_indices, 0..) |family, i| {
            if (family.queue_flags.transfer and
                !family.queue_flags.graphics and
                !family.queue_flags.compute)
            {
                transfer = @intCast(i);
                break;
            }
        }

        return .init(.{
            .graphics = graphics,
            .compute = compute,
            .transfer = transfer,
        });
    }

    pub fn destroy(d_obj: *Object(Device)) void {
        const d = d_obj.body();
        d.handle.deviceWaitIdle() catch {};
        for (d.queue_states[0..d.queue_state_count]) |*queue| {
            queue.timeline.destroyVkDevice(d.*.handle);
            d.handle.destroyCommandPool(queue.command_pool, null);
            queue.free_command_buffers.deinit(d.gpa);
            queue.pending_command_buffers.deinit(d.gpa);
        }
        d.texture_init_timeline.semaphore.destroyVkDevice(d.handle);
        d.handle.destroyDescriptorSetLayout(d.texture_heap_set_layout, null);
        d.handle.destroyDevice(null);
        d.gpa.destroy(d.handle.wrapper);
        // TODO: make a debug gpa and uncomment next line
        // for (d.heap.entries.items) |entry| entry.destroy(d);
        d.heap.entries.deinit(d.gpa);
        d.pending_texture_inits.deinit(d.gpa);
        const gpa = d.gpa;
        gpa.destroy(d);
    }

    pub fn surfaceSupportedUsage(d: *Object(Device), surface: *Object(Surface)) sf.TextureUsage {
        return surfaceSupportedUsageInner(d.body(), surface.body()) catch @panic("TODO"); // TODO: move errors to surface creation
    }
    fn surfaceSupportedUsageInner(d: *Device, surface: *Surface) !sf.TextureUsage {
        const vk_capabilities = try d.instance.handle.getPhysicalDeviceSurfaceCapabilitiesKHR(d.physical_device, surface.handle);
        return to_sf.usageFlags(vk_capabilities.supported_usage_flags);
    }

    pub fn surfaceFormats(
        d: *Object(Device),
        surface: *Object(Surface),
        formats_buffer_size: usize,
        formats_buffer: ?[*]sf.Format,
        formats_count: *usize,
    ) void {
        surfaceFormatsInner(
            d.body(),
            surface.body(),
            if (formats_buffer) |buf| buf[0..formats_buffer_size] else null,
            formats_count,
        ) catch @panic("TODO"); // TODO: move errors to surface creation
    }
    fn surfaceFormatsInner(
        d: *Device,
        surface: *Surface,
        formats_buffer_opt: ?[]sf.Format,
        formats_count: *usize,
    ) !void {
        var arena_impl: std.heap.ArenaAllocator = .init(d.gpa);
        defer arena_impl.deinit();
        const arena = arena_impl.allocator();

        const vk_formats = try d.instance.handle.getPhysicalDeviceSurfaceFormatsAllocKHR(
            d.physical_device,
            surface.handle,
            arena,
        );
        var formats: std.ArrayList(sf.Format) = try .initCapacity(arena, vk_formats.len);
        for (vk_formats) |vk_format| {
            formats.appendAssumeCapacity(to_sf.format(vk_format.format) orelse continue);
        }

        formats_count.* = formats.items.len;
        errdefer formats_count.* = 0;
        const formats_buffer = formats_buffer_opt orelse return;
        @memcpy(
            formats_buffer[0..@min(formats_buffer.len, formats.items.len)],
            formats.items[0..@min(formats_buffer.len, formats.items.len)],
        );
    }

    pub fn surfacePresentModes(
        d: *Object(Device),
        surface: *Object(Surface),
        modes_buffer_size: usize,
        modes_buffer: ?[*]sf.PresentMode,
        modes_count: *usize,
    ) void {
        surfacePresentModesInner(
            d.body(),
            surface.body(),
            if (modes_buffer) |buf| buf[0..modes_buffer_size] else null,
            modes_count,
        ) catch @panic("TODO"); // TODO: move errors to surface creation
    }
    fn surfacePresentModesInner(
        d: *Device,
        surface: *Surface,
        modes_buffer_opt: ?[]sf.PresentMode,
        modes_count: *usize,
    ) !void {
        var arena_impl: std.heap.ArenaAllocator = .init(d.gpa);
        defer arena_impl.deinit();
        const arena = arena_impl.allocator();

        const vk_modes = try d.instance.handle.getPhysicalDeviceSurfacePresentModesAllocKHR(
            d.physical_device,
            surface.handle,
            arena,
        );
        var modes: std.ArrayList(sf.PresentMode) = try .initCapacity(arena, vk_modes.len);
        for (vk_modes) |vk_mode| {
            modes.appendAssumeCapacity(to_sf.presentMode(vk_mode) orelse continue);
        }

        modes_count.* = modes.items.len;
        errdefer modes_count.* = 0;
        const modes_buffer = modes_buffer_opt orelse return;
        @memcpy(
            modes_buffer[0..@min(modes_buffer.len, modes.items.len)],
            modes.items[0..@min(modes_buffer.len, modes.items.len)],
        );
    }

    pub fn hostFromDevicePointer(d: *Object(Device), ptr: sf.DeviceAddress) *anyopaque {
        const entry = d.body().heap.entryFromAddr(ptr);
        const offset = ptr - entry.device_addr;
        return @ptrFromInt(entry.host_addr.? + offset);
    }

    pub fn alloc(
        d: *Object(Device),
        bytes: usize,
        alignment: usize,
        memory: sf.MemoryKind,
        mapped_memory: *sf.HostDeviceAddress,
    ) !void {
        mapped_memory.* = allocInner(d.body(), bytes, .fromByteUnits(alignment), memory) catch |err| return switch (err) {
            error.InvalidExternalHandle => @panic("unreachable"),

            error.InvalidOpaqueCaptureAddressKHR,
            error.Unknown,
            error.MemoryMapFailed,
            error.OutOfHostMemory,
            error.OutOfMemory,
            => error.OutOfMemory,
            error.OutOfDeviceMemory => error.OutOfDeviceMemory,
        };
    }
    fn allocInner(
        d: *Device,
        bytes: usize,
        alignment: std.mem.Alignment,
        memory: sf.MemoryKind,
    ) !sf.HostDeviceAddress {
        std.debug.assert(bytes > 0);

        const usage: vk.BufferUsageFlags = switch (memory) {
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

        var families_buf: [Device.max_queue_state_count]u32 = undefined;
        for (d.queue_states[0..d.queue_state_count], 0..) |q, i| families_buf[i] = q.family;
        const families = families_buf[0..d.queue_state_count];

        const concurrent = families.len > 1;
        var buffer_info: vk.BufferCreateInfo = .{
            .size = bytes,
            .usage = usage,
            .sharing_mode = if (concurrent) .concurrent else .exclusive,
            .queue_family_index_count = if (concurrent) @intCast(families.len) else 0,
            .p_queue_family_indices = if (concurrent) families.ptr else null,
        };
        var buffer = try d.handle.createBuffer(&buffer_info, null);
        errdefer d.handle.destroyBuffer(buffer, null);

        var buffer_memory_requirements = d.handle.getBufferMemoryRequirements(buffer);

        const padded = buffer_memory_requirements.alignment < alignment.toByteUnits();
        if (padded) {
            d.handle.destroyBuffer(buffer, null);
            buffer_info.size = bytes + alignment.toByteUnits() - 1;
            buffer = try d.handle.createBuffer(&buffer_info, null);
            buffer_memory_requirements = d.handle.getBufferMemoryRequirements(buffer);
        }

        const memory_types = switch (memory) {
            .upload, .readback => buffer_memory_requirements.memory_type_bits,
            .device_local => bits: {
                const colors = probeImageMemoryKindBits(d.*, .r8g8b8a8_unorm, .{
                    .sampled = true,
                    .transfer_dst = true,
                    .color_attachment = true,
                });
                const depths = probeImageMemoryKindBits(d.*, .d32_sfloat, .{
                    .depth_stencil_attachment = true,
                    .sampled = true,
                });
                break :bits buffer_memory_requirements.memory_type_bits & colors & depths;
            },
        };

        const properties: vk.MemoryPropertyFlags = switch (memory) {
            .upload => .{
                .device_local = d.has_host_visible_device_local,
                .host_visible = true,
                .host_coherent = true,
            },
            .device_local => .{
                .device_local = true,
            },
            .readback => .{
                .host_visible = true,
                .host_cached = true,
                .host_coherent = true,
            },
        };
        const alloc_flags: vk.MemoryAllocateFlagsInfo = .{
            .flags = .{ .device_address = true },
            .device_mask = 0,
        };
        const buffer_memory = try d.handle.allocateMemory(&.{
            .p_next = &alloc_flags,
            .allocation_size = buffer_memory_requirements.size,
            .memory_type_index = findMemoryKind(d.*, memory_types, properties),
        }, null);
        errdefer d.handle.freeMemory(buffer_memory, null);

        try d.handle.bindBufferMemory(buffer, buffer_memory, 0);

        const raw_device_addr = d.handle.getBufferDeviceAddress(&.{ .buffer = buffer });
        const device_addr = std.mem.alignForward(u64, raw_device_addr, alignment.toByteUnits());
        const delta: usize = @intCast(device_addr - raw_device_addr);
        if (!padded) std.debug.assert(delta == 0);
        std.debug.assert(delta + bytes <= buffer_info.size);

        const host_addr: ?usize = switch (memory) {
            .readback, .upload => @intFromPtr(
                try d.handle.mapMemory(buffer_memory, 0, vk.WHOLE_SIZE, .{}),
            ) + delta,
            .device_local => null,
        };

        try d.heap.insert(d.gpa, .{
            .buffer = buffer,
            .memory = buffer_memory,
            .size = bytes,
            .device_addr = device_addr,
            .host_addr = host_addr,
        });

        return .{
            .device = device_addr,
            .host = if (host_addr) |addr| @ptrFromInt(addr) else undefined,
        };
    }
    fn findMemoryKind(d: Device, type_filter: u32, properties: vk.MemoryPropertyFlags) u32 {
        for (0..d.memory_properties.memory_type_count) |i| {
            if ((type_filter & (@as(u32, 1) << @intCast(i))) != 0 and
                (d.memory_properties.memory_types[i].property_flags.intersect(properties)) == properties)
            {
                return @intCast(i);
            }
        }
        @panic(""); // TODO
    }
    fn probeImageMemoryKindBits(d: Device, format: vk.Format, usage: vk.ImageUsageFlags) u32 {
        const ici: vk.ImageCreateInfo = .{
            .image_type = .@"2d",
            .format = format,
            .extent = .{ .width = 16, .height = 16, .depth = 1 },
            .mip_levels = 1,
            .array_layers = 1,
            .samples = .{ .@"1" = true },
            .tiling = .optimal,
            .usage = usage,
            .sharing_mode = .exclusive,
            .initial_layout = .undefined,
        };
        var req: vk.MemoryRequirements2 = .{ .memory_requirements = undefined };
        d.handle.getDeviceImageMemoryRequirements(&.{ .plane_aspect = .{}, .p_create_info = &ici }, &req);
        return req.memory_requirements.memory_type_bits;
    }

    pub fn free(d: *Object(Device), ptr: sf.DeviceAddress) void {
        const index = d.body().heap.indexFromAddr(ptr);
        var entry = d.body().heap.entries.orderedRemove(index);
        entry.destroy(d.body().*);
    }

    fn descriptorBufferProperties(d: *Device) *vk.PhysicalDeviceDescriptorBufferPropertiesEXT {
        if (d.descriptor_buffer_properties == null) {
            var buffer_properties = std.mem.zeroInit(vk.PhysicalDeviceDescriptorBufferPropertiesEXT, .{});
            var properties_2: vk.PhysicalDeviceProperties2 = .{ .p_next = &buffer_properties, .properties = undefined };
            d.instance.handle.getPhysicalDeviceProperties2(d.physical_device, &properties_2);
            d.descriptor_buffer_properties = buffer_properties;
        }
        return &d.descriptor_buffer_properties.?;
    }

    fn acquireCommandBuffer(d: *Device, queue_kind: sf.QueueKind) !CommandBuffer {
        const queue_id = d.queue_id_from_type.get(queue_kind);
        const queue_state = d.queueStateForQueueId(queue_id);
        if (queue_state.free_command_buffers.pop()) |command_buffer| {
            try d.handle.resetCommandBuffer(command_buffer, .{});
            return .{ .handle = command_buffer, .queue_id = queue_id, .d = d };
        }
        const alloc_info: vk.CommandBufferAllocateInfo = .{
            .command_pool = queue_state.command_pool,
            .level = .primary,
            .command_buffer_count = 1,
        };
        var command_buffer: vk.CommandBuffer = undefined;
        try d.handle.allocateCommandBuffers(&alloc_info, (&command_buffer)[0..1]);
        return .{ .handle = command_buffer, .queue_id = queue_id, .d = d };
    }

    fn queueStateForQueueId(d: *Device, queue_id: QueueId) *QueueState {
        return &d.queue_states[@backingInt(queue_id)];
    }

    fn reclaimCompletedCommandBuffers(d: *Device) void {
        for (d.queue_states[0..d.queue_state_count], 0..) |*queue_state, queue_index| {
            const queue_id: QueueId = @fromBackingInt(@intCast(queue_index));
            const list = &queue_state.pending_command_buffers;
            if (list.items.len == 0) continue;
            const timeline = queue_state.timeline;
            const completed = d.handle.getSemaphoreCounterValue(timeline.handle) catch continue;
            var n: usize = 0;
            while (n < list.items.len and list.items[n].value <= completed) : (n += 1) {
                d.releaseCommandBuffer(.{
                    .handle = list.items[n].command_buffer,
                    .queue_id = queue_id,
                    .d = d,
                });
            }
            const rest = list.items[n..];
            @memmove(list.items[0..rest.len], rest);
            list.items.len = rest.len;
        }
    }

    fn releaseCommandBuffer(d: *Device, command_buffer: CommandBuffer) void {
        const queue_state = d.queueStateForQueueId(command_buffer.queue_id);
        queue_state.free_command_buffers.append(d.gpa, command_buffer.handle) catch {
            d.handle.freeCommandBuffers(queue_state.command_pool, &.{command_buffer.handle});
        };
    }
};

pub const Queue = struct {
    id: Device.QueueId,
    queue_kind: sf.QueueKind,
    d: *Device,

    pub fn getQueue(d_obj: *Object(Device), queue_kind: sf.QueueKind) *Object(Queue) {
        const d = d_obj.body();
        const id = d.queue_id_from_type.get(queue_kind);
        const queue = d.queues.getPtr(queue_kind);
        queue.set(d.table, .{ .id = id, .queue_kind = queue_kind, .d = d });
        return queue;
    }

    pub fn startCommandRecording(queue: *Object(Queue), command_buffer: **Object(CommandBuffer)) !void {
        const d = queue.body().d;
        const cb = try d.command_buffers.create(d.gpa);
        cb.set(d.table, startCommandRecordingInner(queue.body()) catch |err| return switch (err) {
            error.OutOfHostMemory => error.OutOfMemory,
            error.OutOfDeviceMemory, error.Unknown => |e| e,
        });
        command_buffer.* = cb;
    }
    fn startCommandRecordingInner(queue: *const Queue) !CommandBuffer {
        queue.d.reclaimCompletedCommandBuffers();
        const command_buffer = try queue.d.acquireCommandBuffer(queue.queue_kind);
        errdefer queue.d.releaseCommandBuffer(command_buffer);

        const begin_info: vk.CommandBufferBeginInfo = .{ .flags = .{ .one_time_submit = true } };
        try queue.d.handle.beginCommandBuffer(command_buffer.handle, &begin_info);

        return command_buffer;
    }

    pub fn submit(
        queue: *Object(Queue),
        command_buffer_count: usize,
        command_buffers: [*]const *Object(CommandBuffer),
    ) !void {
        submitInner(
            queue.body(),
            command_buffers[0..command_buffer_count],
            null,
        ) catch |err| return switch (err) {
            error.OutOfMemory, error.OutOfHostMemory => error.OutOfMemory,
            error.OutOfDeviceMemory, error.DeviceLost => |e| e,
            error.InvalidVideoStdParametersKHR, error.Unknown => error.Unknown,
        };
    }

    pub fn submitAndSignal(
        queue: *Object(Queue),
        command_buffer_count: usize,
        command_buffers: [*]const *Object(CommandBuffer),
        signal_semaphore: *Object(Semaphore),
        signal_value: u64,
    ) !void {
        submitInner(
            queue.body(),
            command_buffers[0..command_buffer_count],
            .{ .semaphore = signal_semaphore.body(), .value = signal_value },
        ) catch |err| return switch (err) {
            error.OutOfMemory, error.OutOfHostMemory => error.OutOfMemory,
            error.OutOfDeviceMemory, error.DeviceLost => |e| e,
            error.InvalidVideoStdParametersKHR, error.Unknown => error.Unknown,
        };
    }

    const Signal = struct {
        semaphore: *Semaphore,
        value: u64,
    };
    fn submitInner(
        queue: *Queue,
        command_buffers: []const *Object(CommandBuffer),
        extra_signal: ?Signal,
    ) !void {
        const d = queue.d;
        const gpa = d.gpa;
        const queue_state = d.queueStateForQueueId(queue.id);
        const texture_init_timeline = &d.texture_init_timeline;

        errdefer for (command_buffers) |command_buffer| d.releaseCommandBuffer(command_buffer.body().*);

        const image_count = d.pending_texture_inits.count();

        const barriers = try gpa.alloc(vk.ImageMemoryBarrier2, image_count);
        defer gpa.free(barriers);

        var texture_init_command_buffer: ?CommandBuffer = null;
        errdefer if (texture_init_command_buffer) |cb| d.releaseCommandBuffer(cb);

        if (image_count != 0) {
            var image_it = d.pending_texture_inits.iterator();
            for (barriers) |*barrier| {
                const entry = image_it.next().?;
                const image = entry.key_ptr.*;
                const info = entry.value_ptr.*;

                barrier.* = .{
                    .dst_stage_mask = .{ .all_commands = true },
                    .dst_access_mask = .{ .memory_read = true, .memory_write = true },
                    .old_layout = .undefined,
                    .new_layout = .general,
                    .src_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
                    .dst_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
                    .image = image,
                    .subresource_range = .{
                        .aspect_mask = to_vk.aspectsForFormat(info.format),
                        .base_mip_level = 0,
                        .level_count = info.mip_count,
                        .base_array_layer = 0,
                        .layer_count = info.layer_count,
                    },
                };
            }

            const cb = try queue.startCommandRecordingInner();
            texture_init_command_buffer = cb;

            d.handle.cmdPipelineBarrier2(cb.handle, &.{
                .image_memory_barrier_count = @intCast(barriers.len),
                .p_image_memory_barriers = barriers.ptr,
            });
            try d.handle.endCommandBuffer(cb.handle);
        }

        const submit_buffers = try gpa.alloc(vk.CommandBufferSubmitInfo, command_buffers.len);
        defer gpa.free(submit_buffers);
        for (command_buffers, submit_buffers) |command_buffer, *submit_buffer| {
            try d.handle.endCommandBuffer(command_buffer.body().handle);
            submit_buffer.* = .{
                .command_buffer = command_buffer.body().handle,
                .device_mask = 0,
            };
        }

        const pending_count = command_buffers.len + @intFromBool(texture_init_command_buffer != null);
        try queue_state.pending_command_buffers.ensureUnusedCapacity(gpa, pending_count);

        const has_transitions = texture_init_command_buffer != null;

        const init_previous = texture_init_timeline.value;
        const init_target = if (has_transitions) init_previous + 1 else init_previous;

        const timeline = queue_state.timeline;
        const transition_value = queue_state.last_submitted + 1;
        const work_value = if (has_transitions) transition_value + 1 else transition_value;

        var submits: [2]vk.SubmitInfo2 = undefined;
        var submit_count: usize = 0;

        var transition_submit_buffer: vk.CommandBufferSubmitInfo = undefined;
        var transition_waits: [1]vk.SemaphoreSubmitInfo = undefined;
        var transition_signals: [2]vk.SemaphoreSubmitInfo = undefined;

        if (texture_init_command_buffer) |cb| {
            transition_submit_buffer = .{ .command_buffer = cb.handle, .device_mask = 0 };

            transition_waits[0] = .{
                .semaphore = texture_init_timeline.semaphore.handle,
                .value = init_previous,
                .stage_mask = .{ .all_commands = true },
                .device_index = 0,
            };
            transition_signals[0] = .{
                .semaphore = timeline.handle,
                .value = transition_value,
                .stage_mask = .{ .all_commands = true },
                .device_index = 0,
            };
            transition_signals[1] = .{
                .semaphore = texture_init_timeline.semaphore.handle,
                .value = init_target,
                .stage_mask = .{ .all_commands = true },
                .device_index = 0,
            };

            submits[submit_count] = .{
                .wait_semaphore_info_count = 1,
                .p_wait_semaphore_infos = &transition_waits,
                .command_buffer_info_count = 1,
                .p_command_buffer_infos = @ptrCast(&transition_submit_buffer),
                .signal_semaphore_info_count = 2,
                .p_signal_semaphore_infos = &transition_signals,
            };
            submit_count += 1;
        }

        var work_waits: [1]vk.SemaphoreSubmitInfo = .{.{
            .semaphore = texture_init_timeline.semaphore.handle,
            .value = init_target,
            .stage_mask = .{ .all_commands = true },
            .device_index = 0,
        }};

        var work_signals: [2]vk.SemaphoreSubmitInfo = undefined;
        var work_signal_count: u32 = 1;
        work_signals[0] = .{
            .semaphore = timeline.handle,
            .value = work_value,
            .stage_mask = .{ .all_commands = true },
            .device_index = 0,
        };
        if (extra_signal) |signal| {
            work_signals[1] = .{
                .semaphore = signal.semaphore.handle,
                .value = signal.value,
                .stage_mask = .{ .all_commands = true },
                .device_index = 0,
            };
            work_signal_count = 2;
        }

        submits[submit_count] = .{
            .wait_semaphore_info_count = 1,
            .p_wait_semaphore_infos = &work_waits,
            .command_buffer_info_count = @intCast(submit_buffers.len),
            .p_command_buffer_infos = submit_buffers.ptr,
            .signal_semaphore_info_count = work_signal_count,
            .p_signal_semaphore_infos = &work_signals,
        };
        submit_count += 1;

        try d.handle.queueSubmit2(queue_state.queue, submits[0..submit_count], .null);

        texture_init_timeline.value = init_target;
        queue_state.last_submitted = work_value;

        if (texture_init_command_buffer) |cb| {
            d.pending_texture_inits.clearRetainingCapacity();
            queue_state.pending_command_buffers.appendAssumeCapacity(.{
                .value = transition_value,
                .command_buffer = cb.handle,
            });
            texture_init_command_buffer = null;
        }
        for (command_buffers) |command_buffer| {
            queue_state.pending_command_buffers.appendAssumeCapacity(.{
                .value = work_value,
                .command_buffer = command_buffer.body().handle,
            });
            d.command_buffers.destroy(command_buffer);
        }
    }
};

pub const Semaphore = struct {
    handle: vk.Semaphore,
    d: *Device,

    pub fn create(d: *Object(Device), init_value: u64, semaphore: **Object(Semaphore)) !void {
        semaphore.* = createInner(d.body(), init_value) catch |err| return switch (err) {
            error.OutOfMemory, error.OutOfHostMemory => error.OutOfMemory,
            error.OutOfDeviceMemory => |e| e,
            error.Unknown => error.Unknown,
        };
    }
    fn createInner(d: *Device, init_value: u64) !*Object(Semaphore) {
        const semaphore = try d.semaphores.create(d.gpa);
        semaphore.set(d.table, try createVkDevice(d.handle, init_value));
        semaphore.body().d = d;
        return semaphore;
    }

    pub fn destroy(semaphore: *Object(Semaphore)) void {
        destroyVkDevice(semaphore.body(), semaphore.body().d.handle);
        semaphore.body().d.semaphores.destroy(semaphore);
    }

    pub fn wait(semaphore: *Object(Semaphore), value: u64) !void {
        waitInner(semaphore.body(), value) catch |err| return switch (err) {
            error.OutOfHostMemory => error.OutOfMemory,
            error.OutOfDeviceMemory, error.Unknown, error.DeviceLost => |e| e,
        };
    }
    fn waitInner(semaphore: *Semaphore, value: u64) !void {
        const wait_info: vk.SemaphoreWaitInfo = .{
            .semaphore_count = 1,
            .p_semaphores = &.{semaphore.handle},
            .p_values = &.{value},
        };
        _ = try semaphore.d.handle.waitSemaphores(&wait_info, std.math.maxInt(u64));
    }

    fn createVkDevice(device: vk.DeviceProxy, init_value: u64) !Semaphore {
        const semaphore_type: vk.SemaphoreTypeCreateInfo = .{
            .semaphore_type = .timeline,
            .initial_value = init_value,
        };
        const timeline_create_info: vk.SemaphoreCreateInfo = .{ .p_next = &semaphore_type };
        const semaphore = try device.createSemaphore(&timeline_create_info, null);
        return .{ .handle = semaphore, .d = undefined };
    }

    fn destroyVkDevice(semaphore: *Semaphore, device: vk.DeviceProxy) void {
        device.destroySemaphore(semaphore.handle, null);
    }
};

pub const Swapchain = struct {
    handle: vk.SwapchainKHR,
    surface: vk.SurfaceKHR,
    desc: sf.SwapchainDesc,
    queue: *Queue,

    textures: []SwapchainTexture,
    acquire_fence: vk.Fence,
    current: u32,

    needs_recreate: bool,

    d: *Device,

    const SwapchainTexture = struct {
        texture: Object(Texture),
        /// general -> present_src
        present_command_buffer: CommandBuffer,
        /// binary
        present_semaphore: vk.Semaphore,
    };

    pub fn create(
        queue: *Object(Queue),
        surface: *Object(Surface),
        desc: sf.SwapchainDesc,
        swapchain: **Object(Swapchain),
    ) !void {
        swapchain.* = createInner(queue.body(), surface.body(), desc) catch |err| return switch (err) {
            error.OutOfMemory, error.OutOfHostMemory => error.OutOfMemory,
            error.OutOfDeviceMemory, error.Unknown => |e| e,
            error.SurfaceLostKHR => error.SurfaceLost,
        };
    }
    fn createInner(
        queue: *Queue,
        surface: *Surface,
        desc: sf.SwapchainDesc,
    ) !*Object(Swapchain) {
        const queue_family = queue.d.queueStateForQueueId(queue.id).family;
        // TODO: move to adapter picking
        std.debug.assert(try queue.d.instance.handle.getPhysicalDeviceSurfaceSupportKHR(queue.d.physical_device, queue_family, surface.handle) == .true);
        const swapchain = try queue.d.swapchains.create(queue.d.gpa);
        swapchain.set(queue.d.table, .{
            .handle = .null,
            .surface = surface.handle,
            .desc = desc,
            .queue = queue,
            .textures = &.{},
            .acquire_fence = try queue.d.handle.createFence(&.{}, null),
            .current = undefined,
            .needs_recreate = true,
            .d = queue.d,
        });
        return swapchain;
    }

    pub fn destroy(swapchain_obj: *Object(Swapchain)) void {
        const swapchain = swapchain_obj.body();
        _ = swapchain.d.handle.queueWaitIdle(swapchain.d.queueStateForQueueId(swapchain.queue.id).queue) catch {};
        swapchain.destroyImageResources();
        swapchain.d.handle.destroySwapchainKHR(swapchain.handle, null);
        swapchain.d.handle.destroyFence(swapchain.acquire_fence, null);
        swapchain.d.gpa.destroy(swapchain);
    }

    pub fn acquire(
        swapchain: *Object(Swapchain),
        width: u32,
        height: u32,
        back_buffer: *sf.BackBuffer,
    ) !void {
        back_buffer.* = acquireInner(
            swapchain.body(),
            width,
            height,
        ) catch |err| return switch (err) {
            error.OutOfHostMemory, error.OutOfMemory => error.OutOfMemory,
            error.CompressionExhaustedEXT, error.OutOfDeviceMemory => error.OutOfDeviceMemory,
            error.FullScreenExclusiveModeLostEXT,
            error.NativeWindowInUseKHR,
            error.SurfaceLostKHR,
            error.SurfaceLost,
            => error.SurfaceLost,
            error.InvalidVideoStdParametersKHR,
            error.InvalidOpaqueCaptureAddressKHR,
            error.InitializationFailed,
            error.Unknown,
            => error.Unknown,
            error.DeviceLost => |e| e,
        };
    }
    fn acquireInner(
        swapchain: *Swapchain,
        width: u32,
        height: u32,
    ) !sf.BackBuffer {
        const queue = swapchain.queue;
        var attempts: u32 = 0;
        while (true) : (attempts += 1) {
            if (attempts > 32) return error.SurfaceLost;
            if (swapchain.needs_recreate) try swapchain.recreate(queue, width, height);

            const result = swapchain.d.handle.acquireNextImageKHR(
                swapchain.handle,
                std.math.maxInt(u64),
                .null,
                swapchain.acquire_fence,
            ) catch |err| switch (err) {
                error.OutOfDateKHR => {
                    swapchain.needs_recreate = true;
                    continue;
                },
                else => |e| return e,
            };
            const index = result.image_index;
            if (result.result == .suboptimal_khr) swapchain.needs_recreate = true;

            // TODO: make async
            _ = try swapchain.d.handle.waitForFences(&.{swapchain.acquire_fence}, .true, std.math.maxInt(u64));
            try swapchain.d.handle.resetFences(&.{swapchain.acquire_fence});

            swapchain.current = index;
            const texture = &swapchain.textures[index].texture;

            try swapchain.d.pending_texture_inits.put(swapchain.d.gpa, texture.body().image, texture.body().desc);

            return .{
                .extent = texture.body().desc.dimensions[0..2].*,
                .texture = @ptrCast(texture),
            };
        }
    }
    fn recreate(swapchain: *Swapchain, queue: *Queue, width: u32, height: u32) !void { // TODO: inline into callsite?
        const d = swapchain.d;
        try d.handle.queueWaitIdle(d.queueStateForQueueId(queue.id).queue);

        swapchain.destroyImageResources();

        const capabilities = try d.instance.handle.getPhysicalDeviceSurfaceCapabilitiesKHR(d.physical_device, swapchain.surface);

        const min_image_extent = capabilities.min_image_extent;
        const max_image_extent = capabilities.max_image_extent;
        const surface_extent: vk.Extent2D = switch (capabilities.current_extent.width != std.math.maxInt(u32)) {
            true => capabilities.current_extent,
            false => .{
                .width = std.math.clamp(width, min_image_extent.width, max_image_extent.width),
                .height = std.math.clamp(height, min_image_extent.height, max_image_extent.height),
            },
        };

        var min_image_count = capabilities.min_image_count + 1;
        if (capabilities.max_image_count != 0) min_image_count = @min(min_image_count, capabilities.max_image_count);

        const create_info: vk.SwapchainCreateInfoKHR = .{
            .surface = swapchain.surface,
            .min_image_count = min_image_count,
            .image_format = to_vk.format(swapchain.desc.format),
            .image_color_space = .srgb_nonlinear_khr,
            .image_extent = surface_extent,
            .image_array_layers = 1,
            .image_usage = to_vk.usageFlags(swapchain.desc.usage),
            .image_sharing_mode = .exclusive,
            .queue_family_index_count = 0,
            .p_queue_family_indices = null,
            .pre_transform = capabilities.current_transform,
            .composite_alpha = .{ .opaque_khr = true },
            .present_mode = switch (swapchain.desc.present_mode) {
                .immediate => .immediate_khr,
                .mailbox => .mailbox_khr,
                .fifo => .fifo_khr,
                .fifo_relaxed => .fifo_relaxed_khr,
            },
            .clipped = .true,
            .old_swapchain = swapchain.handle,
        };

        const old = swapchain.handle;
        swapchain.handle = try d.handle.createSwapchainKHR(&create_info, null);
        if (old != .null) d.handle.destroySwapchainKHR(old, null);

        const images = try d.handle.getSwapchainImagesAllocKHR(swapchain.handle, d.gpa);
        defer d.gpa.free(images);

        const textures = try d.gpa.alloc(SwapchainTexture, images.len);
        errdefer d.gpa.free(textures);

        for (textures, images) |*texture, image| {
            const texture_info: sf.TextureDesc = .{
                .type = .@"2d",
                .dimensions = .{ surface_extent.width, surface_extent.height, 1 },
                .mip_count = 1,
                .layer_count = 1,
                .format = swapchain.desc.format,
                .usage = swapchain.desc.usage,
            };

            const present_command_buffer = try d.acquireCommandBuffer(queue.queue_kind);

            const begin_info: vk.CommandBufferBeginInfo = .{ .flags = .{ .simultaneous_use = true } };
            try d.handle.beginCommandBuffer(present_command_buffer.handle, &begin_info);

            const image_barrier: vk.ImageMemoryBarrier2 = .{
                .src_stage_mask = .{ .all_commands = true },
                .src_access_mask = .{ .memory_write = true },
                .old_layout = .general,
                .new_layout = .present_src_khr,
                .src_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
                .dst_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
                .image = image,
                .subresource_range = .{
                    .aspect_mask = to_vk.aspectsForFormat(texture_info.format),
                    .base_mip_level = 0,
                    .level_count = texture_info.mip_count,
                    .base_array_layer = 0,
                    .layer_count = texture_info.layer_count,
                },
            };
            const dependency_info: vk.DependencyInfo = .{
                .image_memory_barrier_count = 1,
                .p_image_memory_barriers = &.{image_barrier},
            };
            d.handle.cmdPipelineBarrier2(present_command_buffer.handle, &dependency_info);

            try d.handle.endCommandBuffer(present_command_buffer.handle);

            const default_view = try Texture.createView(d, image, texture_info, .{});

            texture.* = .{
                .texture = undefined,
                .present_semaphore = try d.handle.createSemaphore(&.{}, null),
                .present_command_buffer = present_command_buffer,
            };
            texture.texture.set(swapchain.d.table, .{
                .image = image,
                .desc = texture_info,
                .default_view = default_view,
                .views = .empty,
                .d = swapchain.d,
            });
        }

        swapchain.textures = textures;
        swapchain.needs_recreate = false;
    }

    pub fn present(swapchain: *Object(Swapchain)) !void {
        presentInner(swapchain.body()) catch |err| return switch (err) {
            error.OutOfHostMemory => error.OutOfMemory,
            error.PresentTimingQueueFullEXT, error.Unknown => error.Unknown,
            error.SurfaceLostKHR,
            error.FullScreenExclusiveModeLostEXT,
            => error.SurfaceLost,
            error.OutOfDeviceMemory, error.DeviceLost => |e| e,
        };
    }
    fn presentInner(swapchain: *Swapchain) !void {
        const queue = swapchain.queue;
        const texture = &swapchain.textures[swapchain.current];
        const queue_state = swapchain.d.queueStateForQueueId(queue.id);

        try swapchain.d.handle.queueSubmit2(
            queue_state.queue,
            &.{.{
                .command_buffer_info_count = 1,
                .p_command_buffer_infos = &.{.{
                    .command_buffer = texture.present_command_buffer.handle,
                    .device_mask = 0,
                }},
                .signal_semaphore_info_count = 1,
                .p_signal_semaphore_infos = &.{.{
                    .semaphore = texture.present_semaphore,
                    .value = 0,
                    .stage_mask = .{ .all_commands = true },
                    .device_index = 0,
                }},
            }},
            .null,
        );

        _ = swapchain.d.handle.queuePresentKHR(queue_state.queue, &.{
            .wait_semaphore_count = 1,
            .p_wait_semaphores = &.{texture.present_semaphore},
            .swapchain_count = 1,
            .p_swapchains = &.{swapchain.handle},
            .p_image_indices = &.{swapchain.current},
        }) catch |err| switch (err) {
            error.OutOfDateKHR => { // TODO: can we avoid the frame drop?
                swapchain.needs_recreate = true;
                return;
            },
            else => |e| return e,
        };
    }

    fn destroyImageResources(swapchain: *Swapchain) void {
        for (swapchain.textures) |*texture| {
            swapchain.d.handle.destroySemaphore(texture.present_semaphore, null);
            swapchain.d.releaseCommandBuffer(texture.present_command_buffer);
            texture.texture.body().destroyOptions(false);
        }
        swapchain.d.gpa.free(swapchain.textures);
        swapchain.textures = &.{};
    }
};

pub const CommandBuffer = struct {
    handle: vk.CommandBuffer,
    queue_id: Device.QueueId,

    pipeline_layout: vk.PipelineLayout = .null,
    pipeline_bind_point: vk.PipelineBindPoint = undefined,
    texture_heap_ptr: ?vk.DeviceAddress = null,

    d: *Device,

    pub fn setActiveTextureHeap(cb_obj: *Object(CommandBuffer), heap_ptr: sf.DeviceAddress) void {
        const cb = cb_obj.body();
        const address: vk.DeviceAddress = heap_ptr;
        if (cb.texture_heap_ptr == address) return;
        const binding_info: vk.DescriptorBufferBindingInfoEXT = .{
            .address = address,
            .usage = .{ .resource_descriptor_buffer_ext = true },
        };
        cb.d.handle.cmdBindDescriptorBuffersEXT(
            cb.handle,
            &.{binding_info},
        );
        cb.texture_heap_ptr = address;
        if (cb.pipeline_layout != .null) {
            cb.setDescriptorBufferOffsets();
        }
    }

    pub fn setPipeline(cb_obj: *Object(CommandBuffer), pipeline_obj: *Object(Pipeline)) void {
        const cb = cb_obj.body();
        const pipeline = pipeline_obj.body();
        cb.d.handle.cmdBindPipeline(
            cb.handle,
            pipeline.bind_point,
            pipeline.handle,
        );
        cb.pipeline_layout = pipeline.pipeline_layout;
        cb.pipeline_bind_point = pipeline.bind_point;
        cb.d.handle.cmdBindDescriptorBufferEmbeddedSamplersEXT(
            cb.handle,
            pipeline.bind_point,
            pipeline.pipeline_layout,
            1,
        );
        if (cb.texture_heap_ptr != null) {
            cb.setDescriptorBufferOffsets();
        }
    }

    pub fn setDepthStencilState(cb_obj: *Object(CommandBuffer), depth_stencil_state: *Object(DepthStencilState)) void {
        const cb = cb_obj.body();
        const desc = &depth_stencil_state.body().desc;

        const depth_test_enable = desc.depth_mode.read or desc.depth_mode.write;
        cb.d.handle.cmdSetDepthTestEnable(cb.handle, .fromBool(depth_test_enable));
        cb.d.handle.cmdSetDepthWriteEnable(cb.handle, .fromBool(desc.depth_mode.write));
        const depth_compare_op = if (desc.depth_mode.read) to_vk.compareOp(desc.depth_test) else .always;
        cb.d.handle.cmdSetDepthCompareOp(cb.handle, depth_compare_op);

        const depth_bias_enable = desc.depth_bias != 0 or desc.depth_bias_slope_factor != 0 or desc.depth_bias_clamp != 0;
        cb.d.handle.cmdSetDepthBiasEnable(cb.handle, .fromBool(depth_bias_enable));
        if (depth_bias_enable) {
            cb.d.handle.cmdSetDepthBias(
                cb.handle,
                desc.depth_bias,
                desc.depth_bias_clamp,
                desc.depth_bias_slope_factor,
            );
        }

        const stencil_enable = !stencilIsNoop(desc.stencil_front) or !stencilIsNoop(desc.stencil_back);
        cb.d.handle.cmdSetStencilTestEnable(cb.handle, .fromBool(stencil_enable));
        if (stencil_enable) {
            const both: vk.StencilFaceFlags = .{ .front = true, .back = true };
            cb.d.handle.cmdSetStencilCompareMask(cb.handle, both, desc.stencil_read_mask);
            cb.d.handle.cmdSetStencilWriteMask(cb.handle, both, desc.stencil_write_mask);

            setStencilFace(cb, .{ .front = true }, desc.stencil_front);
            setStencilFace(cb, .{ .back = true }, desc.stencil_back);
        }
    }
    fn stencilIsNoop(stencil: sf.StencilDesc) bool {
        return stencil.@"test" == .always and stencil.pass_op == .keep and stencil.depth_fail_op == .keep;
    }
    fn setStencilFace(cb: *CommandBuffer, face: vk.StencilFaceFlags, s: sf.StencilDesc) void {
        cb.d.handle.cmdSetStencilOp(
            cb.handle,
            face,
            to_vk.stencilOp(s.fail_op),
            to_vk.stencilOp(s.pass_op),
            to_vk.stencilOp(s.depth_fail_op),
            to_vk.compareOp(s.@"test"),
        );
        cb.d.handle.cmdSetStencilReference(cb.handle, face, s.reference);
    }

    pub fn dispatch(
        cb_obj: *Object(CommandBuffer),
        data: sf.DeviceAddress,
        x: u32,
        y: u32,
        z: u32,
    ) void {
        const cb = cb_obj.body();
        cb.d.handle.cmdPushConstants(
            cb.handle,
            cb.pipeline_layout,
            .{ .compute = true },
            0,
            @sizeOf(vk.DeviceAddress),
            &data,
        );
        cb.d.handle.cmdDispatch(cb.handle, x, y, z);
    }

    pub fn barrier(
        cb_obj: *Object(CommandBuffer),
        before: sf.Stage,
        after: sf.Stage,
        hazard: sf.Hazard,
    ) void {
        const cb = cb_obj.body();
        const src_stage = to_vk.pipelineStage(before);
        var dst_stage = to_vk.pipelineStage(after);
        var dst_access: vk.AccessFlags2 = .{
            .memory_read = true,
            .memory_write = true,
        };
        if (hazard.draw_arguments) {
            dst_stage.draw_indirect = true;
        }
        if (hazard.depth_stencil) {
            dst_stage.early_fragment_tests = true;
            dst_stage.late_fragment_tests = true;
        }
        if (hazard.descriptors) {
            dst_access.descriptor_buffer_read_ext = true;
        }
        const memory_barrier: vk.MemoryBarrier2 = .{
            .src_stage_mask = src_stage,
            .src_access_mask = .{ .memory_write = true },
            .dst_stage_mask = dst_stage,
            .dst_access_mask = dst_access,
        };
        // TODO: VK_KHR_dynamic_rendering_local_read
        const dependency_info: vk.DependencyInfo = .{
            .memory_barrier_count = 1,
            .p_memory_barriers = (&memory_barrier)[0..1],
        };
        cb.d.handle.cmdPipelineBarrier2(cb.handle, &dependency_info);
    }

    /// 256 bytes is a typical optimal alignment for dest
    pub fn copyTextureToBuffer(
        cb_obj: *Object(CommandBuffer),
        source_texture_obj: *Object(Texture),
        destination: sf.DeviceAddress,
    ) void {
        const cb = cb_obj.body();
        const source_texture = source_texture_obj.body();
        const entry, const offset = cb.d.heap.entryAndOffsetFromAddr(destination);
        const region: vk.BufferImageCopy2 = .{
            .buffer_offset = offset,
            .buffer_row_length = 0,
            .buffer_image_height = 0,
            .image_subresource = .{
                .aspect_mask = .{ .color = true },
                .mip_level = 0,
                .base_array_layer = 0,
                .layer_count = source_texture.desc.layer_count,
            },
            .image_offset = .{ .x = 0, .y = 0, .z = 0 },
            .image_extent = .{
                .width = source_texture.desc.dimensions[0],
                .height = source_texture.desc.dimensions[1],
                .depth = source_texture.desc.dimensions[2],
            },
        };
        const info: vk.CopyImageToBufferInfo2 = .{
            .src_image = source_texture.image,
            .src_image_layout = .general,
            .dst_buffer = entry.buffer,
            .region_count = 1,
            .p_regions = (&region)[0..1],
        };
        cb.d.handle.cmdCopyImageToBuffer2(cb.handle, &info);
    }

    pub fn copyBufferToTexture(
        cb_obj: *Object(CommandBuffer),
        source: sf.DeviceAddress,
        destination_texture_obj: *Object(Texture),
    ) void {
        const cb = cb_obj.body();
        const destination_texture = destination_texture_obj.body();
        const entry, const offset = cb.d.heap.entryAndOffsetFromAddr(source);
        const region: vk.BufferImageCopy2 = .{
            .buffer_offset = offset,
            .buffer_row_length = 0,
            .buffer_image_height = 0,
            .image_subresource = .{
                .aspect_mask = .{ .color = true },
                .mip_level = 0,
                .base_array_layer = 0,
                .layer_count = destination_texture.desc.layer_count,
            },
            .image_offset = .{ .x = 0, .y = 0, .z = 0 },
            .image_extent = .{
                .width = destination_texture.desc.dimensions[0],
                .height = destination_texture.desc.dimensions[1],
                .depth = destination_texture.desc.dimensions[2],
            },
        };
        const info: vk.CopyBufferToImageInfo2 = .{
            .dst_image = destination_texture.image,
            .dst_image_layout = .general,
            .src_buffer = entry.buffer,
            .region_count = 1,
            .p_regions = (&region)[0..1],
        };
        cb.d.handle.cmdCopyBufferToImage2(cb.handle, &info);
    }

    pub fn beginRenderPass(cb_obj: *Object(CommandBuffer), desc: sf.RenderPassDesc) void {
        const cb = cb_obj.body();
        const color_targets = if (desc.color_attachments) |color_attachments| color_attachments[0..desc.color_attachment_count] else &.{};
        std.debug.assert(color_targets.len <= 8);

        var color_attachments: [8]vk.RenderingAttachmentInfo = undefined;
        for (color_targets, 0..) |t, i| {
            const texture: *Object(Texture) = @ptrCast(@alignCast(t.texture));
            color_attachments[i] = .{
                .image_view = texture.body().default_view,
                .image_layout = .general,
                .resolve_mode = .{},
                .resolve_image_view = .null,
                .resolve_image_layout = .undefined,
                .load_op = to_vk.attachmentLoadOp(t.load_op),
                .store_op = to_vk.attachmentStoreOp(t.store_op),
                .clear_value = .{ .color = .{ .float_32 = t.clear_color } },
            };
        }

        var depth_attachment: vk.RenderingAttachmentInfo = undefined;
        if (desc.depth_attachment.texture) |t| {
            const texture: *Object(Texture) = @ptrCast(@alignCast(t));
            depth_attachment = .{
                .image_view = texture.body().default_view,
                .image_layout = .general,
                .resolve_mode = .{},
                .resolve_image_view = .null,
                .resolve_image_layout = .undefined,
                .load_op = to_vk.attachmentLoadOp(desc.depth_attachment.load_op),
                .store_op = to_vk.attachmentStoreOp(desc.depth_attachment.store_op),
                .clear_value = .{ .depth_stencil = .{ .depth = desc.depth_attachment.clear_value, .stencil = 0 } },
            };
        }

        var stencil_attachment: vk.RenderingAttachmentInfo = undefined;
        if (desc.stencil_attachment.texture) |t| {
            const texture: *Object(Texture) = @ptrCast(@alignCast(t));
            stencil_attachment = .{
                .image_view = texture.body().default_view,
                .image_layout = .general,
                .resolve_mode = .{},
                .resolve_image_view = .null,
                .resolve_image_layout = .undefined,
                .load_op = to_vk.attachmentLoadOp(desc.stencil_attachment.load_op),
                .store_op = to_vk.attachmentStoreOp(desc.stencil_attachment.store_op),
                .clear_value = .{ .depth_stencil = .{ .depth = 0, .stencil = desc.stencil_attachment.clear_value } },
            };
        }

        const extent: [2]u32 = blk: {
            if (color_targets.len > 0) {
                const texture: *Object(Texture) = @ptrCast(@alignCast(color_targets[0].texture));
                break :blk .{
                    texture.body().desc.dimensions[0],
                    texture.body().desc.dimensions[1],
                };
            }
            if (desc.depth_attachment.texture) |t| {
                const texture: *Object(Texture) = @ptrCast(@alignCast(t));
                break :blk .{ texture.body().desc.dimensions[0], texture.body().desc.dimensions[1] };
            }
            if (desc.stencil_attachment.texture) |t| {
                const texture: *Object(Texture) = @ptrCast(@alignCast(t));
                break :blk .{ texture.body().desc.dimensions[0], texture.body().desc.dimensions[1] };
            }
            unreachable;
        };

        const rendering_info: vk.RenderingInfo = .{
            .render_area = .{
                .offset = .{ .x = 0, .y = 0 },
                .extent = .{ .width = extent[0], .height = extent[1] },
            },
            .layer_count = 1,
            .view_mask = 0,
            .color_attachment_count = @intCast(color_targets.len),
            .p_color_attachments = &color_attachments,
            .p_depth_attachment = if (desc.depth_attachment.texture != null) &depth_attachment else null,
            .p_stencil_attachment = if (desc.stencil_attachment.texture != null) &stencil_attachment else null,
        };
        cb.d.handle.cmdBeginRendering(cb.handle, &rendering_info);

        cb.d.handle.cmdSetViewport(cb.handle, 0, &.{.{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(extent[0]),
            .height = @floatFromInt(extent[1]),
            .min_depth = 0,
            .max_depth = 1,
        }});
        cb.d.handle.cmdSetScissor(cb.handle, 0, &.{.{
            .offset = .{ .x = 0, .y = 0 },
            .extent = .{ .width = extent[0], .height = extent[1] },
        }});
        cb.d.handle.cmdSetDepthTestEnable(cb.handle, .false);
        cb.d.handle.cmdSetDepthWriteEnable(cb.handle, .false);
        cb.d.handle.cmdSetDepthCompareOp(cb.handle, .always);
        cb.d.handle.cmdSetDepthBiasEnable(cb.handle, .false);
        cb.d.handle.cmdSetStencilTestEnable(cb.handle, .false);
    }

    pub fn endRenderPass(cb: *Object(CommandBuffer)) void {
        cb.body().d.handle.cmdEndRendering(cb.body().handle);
    }

    pub fn draw(
        cb: *Object(CommandBuffer),
        vertex_data: sf.DeviceAddress,
        pixel_data: sf.DeviceAddress,
        vertex_count: u32,
        instance_count: u32,
    ) void {
        pushRootPointers(cb.body(), vertex_data, pixel_data);
        cb.body().d.handle.cmdDraw(cb.body().handle, vertex_count, instance_count, 0, 0);
    }

    pub fn drawIndexed(
        cb: *Object(CommandBuffer),
        vertex_data: sf.DeviceAddress,
        pixel_data: sf.DeviceAddress,
        index_type: sf.IndexType,
        indices: sf.DeviceAddress,
        index_count: u32,
    ) void {
        drawIndexedInstanced(cb, vertex_data, pixel_data, index_type, indices, index_count, 1);
    }

    pub fn drawIndexedInstanced(
        cb: *Object(CommandBuffer),
        vertex_data: sf.DeviceAddress,
        pixel_data: sf.DeviceAddress,
        index_type: sf.IndexType,
        indices: sf.DeviceAddress,
        index_count: u32,
        instance_count: u32,
    ) void {
        pushRootPointers(cb.body(), vertex_data, pixel_data);
        bindIndexPointer(cb.body(), index_type, indices);
        cb.body().d.handle.cmdDrawIndexed(cb.body().handle, index_count, instance_count, 0, 0, 0);
    }

    pub fn drawIndexedInstancedIndirect(
        cb: *Object(CommandBuffer),
        vertex_data: sf.DeviceAddress,
        pixel_data: sf.DeviceAddress,
        index_type: sf.IndexType,
        indices: sf.DeviceAddress,
        args: sf.DeviceAddress,
    ) void {
        pushRootPointers(cb.body(), vertex_data, pixel_data);
        bindIndexPointer(cb.body(), index_type, indices);
        const entry, const offset = cb.body().d.heap.entryAndOffsetFromAddr(args);
        cb.body().d.handle.cmdDrawIndexedIndirect(
            cb.body().handle,
            entry.buffer,
            offset,
            1,
            @sizeOf(sf.DrawIndexedArguments),
        );
    }

    fn pushRootPointers(cb: *CommandBuffer, vertex_data: u64, pixel_data: u64) void {
        const addresses = [2]u64{ vertex_data, pixel_data };
        cb.d.handle.cmdPushConstants(
            cb.handle,
            cb.pipeline_layout,
            .{ .vertex = true, .fragment = true },
            0,
            @sizeOf(vk.DeviceAddress) * 2,
            std.mem.asBytes(&addresses),
        );
    }

    fn bindIndexPointer(
        cb: *CommandBuffer,
        index_type: sf.IndexType,
        indices: sf.DeviceAddress,
    ) void {
        const vk_index_type: vk.IndexType = switch (index_type) {
            .uint16 => .uint16,
            .uint32 => .uint32,
        };
        const entry, const offset = cb.d.heap.entryAndOffsetFromAddr(indices);
        cb.d.handle.cmdBindIndexBuffer(cb.handle, entry.buffer, offset, vk_index_type);
    }

    fn setDescriptorBufferOffsets(command_buffer: *CommandBuffer) void {
        command_buffer.d.handle.cmdSetDescriptorBufferOffsetsEXT(
            command_buffer.handle,
            command_buffer.pipeline_bind_point,
            command_buffer.pipeline_layout,
            0,
            &.{0},
            &.{0},
        );
    }
};

pub const DepthStencilState = struct {
    desc: sf.DepthStencilDesc,
    d: *Device,

    pub fn create(d: *Object(Device), desc: sf.DepthStencilDesc, depth_stencil_state: **Object(DepthStencilState)) !void {
        depth_stencil_state.* = try d.body().depth_stencil_states.create(d.body().gpa);
        depth_stencil_state.*.set(d.header, .{ .desc = desc, .d = d.body() });
    }

    pub fn destroy(depth_stencil_state: *Object(DepthStencilState)) void {
        depth_stencil_state.body().d.depth_stencil_states.destroy(depth_stencil_state);
    }
};

pub const Texture = struct {
    image: vk.Image,
    desc: Desc,
    default_view: vk.ImageView,
    views: std.hash_map.AutoHashMapUnmanaged(sf.TextureViewDesc, vk.ImageView),
    d: *Device,

    const Type = sf.TextureDimension;
    const Usage = sf.TextureUsage;
    const Desc = sf.TextureDesc;

    pub const Descriptor = opaque {
        pub fn sizeAndHeapAlign(d_obj: *Object(Device)) sf.SizeAndAlign {
            const d = d_obj.body();
            const buffer_properties = d.descriptorBufferProperties();
            return .{
                .size = @max(
                    buffer_properties.sampled_image_descriptor_size,
                    buffer_properties.storage_image_descriptor_size,
                ),
                .alignment = buffer_properties.descriptor_buffer_offset_alignment,
            };
        }

        pub fn storeDescriptor(d: *Object(Device), descriptor: *const sf.Descriptor, heap_ptr: [*]u8, index: usize) void {
            const size_align = Descriptor.sizeAndHeapAlign(d);
            @memcpy(
                @as([*]u8, @ptrCast(heap_ptr)) + size_align.size * index,
                descriptor.data[0..size_align.size],
            );
        }
    };

    pub fn sizeAndAlign(d_obj: *Object(Device), info: Desc) sf.SizeAndAlign {
        const d = d_obj.body();
        const device_image_memory_requirements: vk.DeviceImageMemoryRequirements = .{
            .p_create_info = &vkImageInfo(info),
            .plane_aspect = to_vk.aspectsForFormat(info.format),
        };
        var req: vk.MemoryRequirements2 = .{ .memory_requirements = undefined };
        d.handle.getDeviceImageMemoryRequirements(&device_image_memory_requirements, &req);
        return .{
            .size = req.memory_requirements.size,
            .alignment = req.memory_requirements.alignment,
        };
    }

    pub fn create(d: *Object(Device), info: Desc, texture_data: sf.DeviceAddress, texture: **Object(Texture)) !void {
        texture.* = createInner(d.body(), info, texture_data) catch |err| return switch (err) {
            error.OutOfHostMemory, error.OutOfMemory => error.OutOfMemory,
            error.InvalidOpaqueCaptureAddressKHR, error.Unknown => error.Unknown,
            error.OutOfDeviceMemory, error.CompressionExhaustedEXT => error.OutOfDeviceMemory,
        };
    }
    fn createInner(d: *Device, info: Desc, texture_data: sf.DeviceAddress) !*Object(Texture) {
        const image = try d.handle.createImage(&vkImageInfo(info), null);
        errdefer d.handle.destroyImage(image, null);

        const entry, const offset = d.heap.entryAndOffsetFromAddr(texture_data);
        try d.handle.bindImageMemory(image, entry.memory, offset);

        const default_view = try createView(d, image, info, .{});
        errdefer d.handle.destroyImageView(default_view, null);

        try d.pending_texture_inits.put(d.gpa, image, info);
        const texture = try d.textures.create(d.gpa);
        texture.set(d.table, .{
            .image = image,
            .desc = info,
            .default_view = default_view,
            .views = .empty,
            .d = d,
        });
        return texture;
    }

    pub fn destroy(texture: *Object(Texture)) void {
        texture.body().destroyOptions(true);
        texture.body().d.textures.destroy(texture);
    }

    fn destroyOptions(texture: *Texture, owns_vk_image: bool) void {
        _ = texture.d.pending_texture_inits.swapRemove(texture.image);
        if (owns_vk_image) texture.d.handle.destroyImage(texture.image, null);
        texture.d.handle.destroyImageView(texture.default_view, null);
        var it = texture.views.valueIterator();
        while (it.next()) |view| texture.d.handle.destroyImageView(view.*, null);
        texture.views.clearRetainingCapacity();
        texture.views.deinit(texture.d.gpa);
    }

    pub fn storageDescriptor(texture: *Object(Texture), view_info: sf.TextureViewDesc, descriptor: *sf.Descriptor) !void {
        descriptor.* = storageDescriptorInner(texture.body(), view_info) catch |err| return switch (err) {
            error.OutOfHostMemory, error.OutOfMemory => error.OutOfMemory,
            error.InvalidOpaqueCaptureAddressKHR, error.Unknown => error.Unknown,
            error.OutOfDeviceMemory => |e| e,
        };
    }
    fn storageDescriptorInner(texture: *Texture, view_info: sf.TextureViewDesc) !sf.Descriptor {
        const view = texture.views.get(view_info) orelse blk: {
            const view = try createView(texture.d, texture.image, texture.desc, view_info);
            try texture.views.put(texture.d.gpa, view_info, view);
            break :blk view;
        };
        const image_info: vk.DescriptorImageInfo = .{
            .image_view = view,
            .image_layout = .general,
            .sampler = .null,
        };
        const get_info: vk.DescriptorGetInfoEXT = .{
            .type = .storage_image,
            .data = .{ .p_storage_image = &image_info },
        };
        const buffer_properties = texture.d.descriptorBufferProperties();
        var descriptor: sf.Descriptor = .{ .data = @splat(0) };
        texture.d.handle.getDescriptorEXT(&get_info, buffer_properties.storage_image_descriptor_size, @ptrCast(&descriptor.data));
        return descriptor;
    }

    pub fn viewDescriptor(texture: *Object(Texture), view_info: sf.TextureViewDesc, descriptor: *sf.Descriptor) !void {
        descriptor.* = viewDescriptorInner(texture.body(), view_info) catch |err| return switch (err) {
            error.OutOfHostMemory, error.OutOfMemory => error.OutOfMemory,
            error.InvalidOpaqueCaptureAddressKHR, error.Unknown => error.Unknown,
            error.OutOfDeviceMemory => |e| e,
        };
    }
    fn viewDescriptorInner(
        texture: *Texture,
        view_info: sf.TextureViewDesc,
    ) !sf.Descriptor {
        const view = texture.views.get(view_info) orelse blk: {
            const view = try createView(texture.d, texture.image, texture.desc, view_info);
            try texture.views.put(texture.d.gpa, view_info, view);
            break :blk view;
        };
        const image_info: vk.DescriptorImageInfo = .{
            .image_view = view,
            .image_layout = .general,
            .sampler = .null,
        };
        const get_info: vk.DescriptorGetInfoEXT = .{
            .type = .sampled_image,
            .data = .{ .p_sampled_image = &image_info },
        };
        const properties = texture.d.descriptorBufferProperties();
        var descriptor: sf.Descriptor = .{ .data = @splat(0) };
        texture.d.handle.getDescriptorEXT(&get_info, properties.sampled_image_descriptor_size, @ptrCast(&descriptor.data));
        return descriptor;
    }

    fn vkImageInfo(info: Desc) vk.ImageCreateInfo {
        return .{
            .image_type = to_vk.textureDimension(info.type),
            .format = to_vk.format(info.format),
            .extent = .{ .width = info.dimensions[0], .height = info.dimensions[1], .depth = info.dimensions[2] },
            .mip_levels = info.mip_count,
            .array_layers = info.layer_count,
            .samples = .{ .@"1" = true },
            .tiling = .optimal,
            .usage = to_vk.usageFlags(info.usage),
            .sharing_mode = .exclusive,
            .initial_layout = .undefined,
        };
    }

    fn createView(d: *Device, image: vk.Image, texture_info: Desc, view_info: sf.TextureViewDesc) !vk.ImageView {
        const mip_count = if (view_info.mip_count == sf.all_mips) vk.REMAINING_MIP_LEVELS else view_info.mip_count;
        const layer_count = if (view_info.layer_count == sf.all_layers) vk.REMAINING_ARRAY_LAYERS else view_info.layer_count;
        const format = if (view_info.format == .none) texture_info.format else view_info.format;
        const info: vk.ImageViewCreateInfo = .{
            .image = image,
            .view_type = to_vk.viewType(texture_info.type),
            .format = to_vk.format(format),
            .subresource_range = .{
                .aspect_mask = to_vk.aspectsForFormat(texture_info.format),
                .base_mip_level = view_info.base_mip,
                .level_count = mip_count,
                .base_array_layer = view_info.base_layer,
                .layer_count = layer_count,
            },
            .components = .{ .r = .identity, .g = .identity, .b = .identity, .a = .identity },
        };
        return d.handle.createImageView(&info, null);
    }
};

pub const Pipeline = struct {
    handle: vk.Pipeline,
    pipeline_layout: vk.PipelineLayout,
    bind_point: vk.PipelineBindPoint,

    samplers: []vk.Sampler,
    sampler_set_layout: vk.DescriptorSetLayout,

    d: *Device,

    pub fn createCompute(
        d: *Object(Device),
        ir_size: usize,
        ir: [*]const u8,
        pipeline: **Object(Pipeline),
    ) !void {
        pipeline.* = createComputeInner(d.body(), ir[0..ir_size]) catch |err| return switch (err) {
            error.OutOfHostMemory, error.OutOfMemory => error.OutOfMemory,
            error.InvalidOpaqueCaptureAddressKHR, error.Unknown => error.Unknown,
            error.InvalidShaderNV, error.MalformedSfir => error.MalformedSfir,
            error.UnsupportedSfirVersion, error.OutOfDeviceMemory => |e| e,
        };
    }
    fn createComputeInner(d: *Device, ir: []const u8) !*Object(Pipeline) {
        const parser = try sfir.parse(ir);
        const spirv = try parser.spirvAlloc(d.gpa);
        defer d.gpa.free(spirv);
        const module = try d.handle.createShaderModule(&.{
            .code_size = spirv.len * @sizeOf(u32),
            .p_code = spirv.ptr,
        }, null);
        defer d.handle.destroyShaderModule(module, null);

        const stage: vk.PipelineShaderStageCreateInfo = .{
            .stage = .{ .compute = true },
            .module = module,
            .p_name = "main",
        };

        const samplers = try d.gpa.alloc(vk.Sampler, parser.samplerCount());
        var vertex_sampler_it = parser.samplerIterator();
        for (samplers) |*sampler| {
            const sampler_info = vertex_sampler_it.next().?;
            const sampler_create_info = to_vk.samplerCreateInfo(sampler_info);
            sampler.* = try d.handle.createSampler(&sampler_create_info, null);
        }

        const push_constant_ranges = [_]vk.PushConstantRange{.{
            .stage_flags = .{ .compute = true },
            .offset = 0,
            .size = @sizeOf(vk.DeviceAddress),
        }};
        const sampler_set_layout = try createSamplerSetLayout(d, samplers, &.{});
        const pipeline_layout = try createPipelineLayout(d, sampler_set_layout, &push_constant_ranges);

        const info: vk.ComputePipelineCreateInfo = .{
            .flags = .{ .descriptor_buffer_ext = true },
            .stage = stage,
            .layout = pipeline_layout,
            .base_pipeline_index = -1,
        };
        var handle: vk.Pipeline = undefined;
        _ = try d.handle.createComputePipelines(.null, &.{info}, null, (&handle)[0..1]);

        const pipeline = try d.pipelines.create(d.gpa);
        pipeline.set(d.table, .{
            .handle = handle,
            .pipeline_layout = pipeline_layout,
            .bind_point = .compute,

            .samplers = samplers,
            .sampler_set_layout = sampler_set_layout,

            .d = d,
        });
        return pipeline;
    }

    pub fn createGraphics(
        d: *Object(Device),
        vertex_ir_size: usize,
        vertex_ir: [*]const u8,
        pixel_ir_size: usize,
        pixel_ir: [*]const u8,
        desc: sf.GraphicsPipelineDesc,
        pipeline: **Object(Pipeline),
    ) !void {
        pipeline.* = createGraphicsInner(
            d.body(),
            vertex_ir[0..vertex_ir_size],
            pixel_ir[0..pixel_ir_size],
            desc,
        ) catch |err| return switch (err) {
            error.OutOfHostMemory, error.OutOfMemory => error.OutOfMemory,
            error.InvalidOpaqueCaptureAddressKHR, error.Unknown => error.Unknown,
            error.InvalidShaderNV, error.MalformedSfir => error.MalformedSfir,
            error.UnsupportedSfirVersion, error.OutOfDeviceMemory => |e| e,
        };
    }
    fn createGraphicsInner(
        d: *Device,
        vertex_ir: []const u8,
        pixel_ir: []const u8,
        desc: sf.GraphicsPipelineDesc,
    ) !*Object(Pipeline) {
        const color_targets = if (desc.color_targets) |color_targets| color_targets[0..desc.color_target_count] else &.{};
        std.debug.assert(color_targets.len <= 8);

        const vertex_parser = try sfir.parse(vertex_ir);
        const vertex_spirv = try vertex_parser.spirvAlloc(d.gpa);
        defer d.gpa.free(vertex_spirv);
        const vert_module = try d.handle.createShaderModule(&.{
            .code_size = vertex_spirv.len * @sizeOf(u32),
            .p_code = vertex_spirv.ptr,
        }, null);
        defer d.handle.destroyShaderModule(vert_module, null);

        const pixel_parser = try sfir.parse(pixel_ir);
        const pixel_spirv = try pixel_parser.spirvAlloc(d.gpa);
        defer d.gpa.free(pixel_spirv);
        const frag_module = try d.handle.createShaderModule(&.{
            .code_size = pixel_spirv.len * @sizeOf(u32),
            .p_code = pixel_spirv.ptr,
        }, null);
        defer d.handle.destroyShaderModule(frag_module, null);

        const stages = [_]vk.PipelineShaderStageCreateInfo{
            .{ .stage = .{ .vertex = true }, .module = vert_module, .p_name = "main" },
            .{ .stage = .{ .fragment = true }, .module = frag_module, .p_name = "main" },
        };

        const vertex_input: vk.PipelineVertexInputStateCreateInfo = .{};

        const input_assembly: vk.PipelineInputAssemblyStateCreateInfo = .{
            .topology = to_vk.topology(desc.topology),
            .primitive_restart_enable = .false,
        };

        const viewport_state: vk.PipelineViewportStateCreateInfo = .{
            .viewport_count = 1,
            .scissor_count = 1,
        };

        const rasterization: vk.PipelineRasterizationStateCreateInfo = .{
            .depth_clamp_enable = .false,
            .rasterizer_discard_enable = .false,
            .polygon_mode = .fill,
            .cull_mode = to_vk.cullMode(desc.cull),
            .front_face = .counter_clockwise,
            .depth_bias_enable = .false,
            .depth_bias_constant_factor = 0,
            .depth_bias_clamp = 0,
            .depth_bias_slope_factor = 0,
            .line_width = 1,
        };

        const multisample: vk.PipelineMultisampleStateCreateInfo = .{
            .rasterization_samples = to_vk.sampleCount(@intCast(desc.sample_count)),
            .sample_shading_enable = .false,
            .min_sample_shading = 0,
            .alpha_to_coverage_enable = if (desc.alpha_to_coverage) .true else .false,
            .alpha_to_one_enable = .false,
        };

        const stencil_placeholder: vk.StencilOpState = std.mem.zeroInit(vk.StencilOpState, .{});
        const depth_stencil: vk.PipelineDepthStencilStateCreateInfo = .{
            .depth_test_enable = .false,
            .depth_write_enable = .false,
            .depth_compare_op = .always,
            .depth_bounds_test_enable = .false,
            .stencil_test_enable = .false,
            .front = stencil_placeholder,
            .back = stencil_placeholder,
            .min_depth_bounds = 0,
            .max_depth_bounds = 1,
        };

        var color_formats: [8]vk.Format = undefined;
        var blend_attachments: [8]vk.PipelineColorBlendAttachmentState = undefined;
        for (color_targets, 0..) |t, i| {
            color_formats[i] = to_vk.format(t.format);
            blend_attachments[i] = if (desc.blend_state) |bs| .{
                .blend_enable = .true,
                .src_color_blend_factor = to_vk.blendFactor(bs.src_color_factor),
                .dst_color_blend_factor = to_vk.blendFactor(bs.dst_color_factor),
                .color_blend_op = to_vk.blendOp(bs.color_op),
                .src_alpha_blend_factor = to_vk.blendFactor(bs.src_alpha_factor),
                .dst_alpha_blend_factor = to_vk.blendFactor(bs.dst_alpha_factor),
                .alpha_blend_op = to_vk.blendOp(bs.alpha_op),
                .color_write_mask = to_vk.writeMask(t.write_mask),
            } else .{
                .blend_enable = .false,
                .src_color_blend_factor = .one,
                .dst_color_blend_factor = .zero,
                .color_blend_op = .add,
                .src_alpha_blend_factor = .one,
                .dst_alpha_blend_factor = .zero,
                .alpha_blend_op = .add,
                .color_write_mask = to_vk.writeMask(t.write_mask),
            };
        }
        const color_blend: vk.PipelineColorBlendStateCreateInfo = .{
            .logic_op_enable = .false,
            .logic_op = .copy,
            .attachment_count = @intCast(color_targets.len),
            .p_attachments = &blend_attachments,
            .blend_constants = .{ 0, 0, 0, 0 },
        };

        const dynamic_states = [_]vk.DynamicState{
            .viewport,
            .scissor,
            .depth_test_enable,
            .depth_write_enable,
            .depth_compare_op,
            .depth_bias_enable,
            .depth_bias,
            .stencil_test_enable,
            .stencil_op,
            .stencil_compare_mask,
            .stencil_write_mask,
            .stencil_reference,
        };
        const dynamic_state: vk.PipelineDynamicStateCreateInfo = .{
            .dynamic_state_count = dynamic_states.len,
            .p_dynamic_states = &dynamic_states,
        };

        const samplers = try d.gpa.alloc(
            vk.Sampler,
            vertex_parser.samplerCount() + pixel_parser.samplerCount(),
        );
        var sampler_i: usize = 0;
        var vertex_sampler_it = vertex_parser.samplerIterator();
        while (vertex_sampler_it.next()) |sampler_info| : (sampler_i += 1) {
            const sampler_create_info = to_vk.samplerCreateInfo(sampler_info);
            samplers[sampler_i] = try d.handle.createSampler(&sampler_create_info, null);
        }
        const vertex_samplers = samplers[0..sampler_i];

        var pixel_sampler_it = pixel_parser.samplerIterator();
        while (pixel_sampler_it.next()) |sampler_info| : (sampler_i += 1) {
            const sampler_create_info = to_vk.samplerCreateInfo(sampler_info);
            samplers[sampler_i] = try d.handle.createSampler(&sampler_create_info, null);
        }
        const pixel_samplers = samplers[vertex_samplers.len..sampler_i];

        const push_constant_range: vk.PushConstantRange = .{
            .stage_flags = .{ .vertex = true, .fragment = true },
            .offset = 0,
            .size = @sizeOf(vk.DeviceAddress) * 2,
        };
        const sampler_set_layout = try createSamplerSetLayout(d, vertex_samplers, pixel_samplers);
        const pipeline_layout = try createPipelineLayout(d, sampler_set_layout, &.{push_constant_range});

        const rendering_info: vk.PipelineRenderingCreateInfo = .{
            .view_mask = 0,
            .color_attachment_count = @intCast(color_targets.len),
            .p_color_attachment_formats = &color_formats,
            .depth_attachment_format = to_vk.format(desc.depth_format),
            .stencil_attachment_format = to_vk.format(desc.stencil_format),
        };
        const info: vk.GraphicsPipelineCreateInfo = .{
            .p_next = &rendering_info,
            .flags = .{ .descriptor_buffer_ext = true },
            .stage_count = stages.len,
            .p_stages = &stages,
            .p_vertex_input_state = &vertex_input,
            .p_input_assembly_state = &input_assembly,
            .p_viewport_state = &viewport_state,
            .p_rasterization_state = &rasterization,
            .p_multisample_state = &multisample,
            .p_depth_stencil_state = &depth_stencil,
            .p_color_blend_state = &color_blend,
            .p_dynamic_state = &dynamic_state,
            .layout = pipeline_layout,
            .render_pass = .null,
            .subpass = 0,
            .base_pipeline_index = -1,
        };
        var handle: vk.Pipeline = undefined;
        _ = try d.handle.createGraphicsPipelines(.null, &.{info}, null, (&handle)[0..1]);

        const pipeline = try d.pipelines.create(d.gpa);
        pipeline.set(d.table, .{
            .handle = handle,
            .pipeline_layout = pipeline_layout,
            .bind_point = .graphics,

            .samplers = samplers,
            .sampler_set_layout = sampler_set_layout,

            .d = d,
        });
        return pipeline;
    }

    pub fn destroy(pipeline_obj: *Object(Pipeline)) void {
        const pipeline = pipeline_obj.body();
        pipeline.d.handle.destroyPipeline(pipeline.handle, null);
        pipeline.d.handle.destroyPipelineLayout(pipeline.pipeline_layout, null);
        pipeline.d.handle.destroyDescriptorSetLayout(pipeline.sampler_set_layout, null);
        for (pipeline.samplers) |sampler| pipeline.d.handle.destroySampler(sampler, null);
        pipeline.d.gpa.free(pipeline.samplers);
        pipeline.d.pipelines.destroy(pipeline_obj);
    }

    fn createSamplerSetLayout(
        d: *Device,
        samplers: []const vk.Sampler,
        pixel_samplers: []const vk.Sampler,
    ) !vk.DescriptorSetLayout {
        var sampler_bindings: [2]vk.DescriptorSetLayoutBinding = undefined;
        var sampler_bindings_count: u32 = 0;

        if (samplers.len != 0) {
            sampler_bindings[sampler_bindings_count] = .{
                .binding = 0,
                .descriptor_type = .sampler,
                .descriptor_count = @intCast(samplers.len),
                .stage_flags = .{ .vertex = true, .fragment = true, .compute = true },
                .p_immutable_samplers = samplers.ptr,
            };
            sampler_bindings_count += 1;
        }
        if (pixel_samplers.len != 0) {
            sampler_bindings[sampler_bindings_count] = .{
                .binding = 1,
                .descriptor_type = .sampler,
                .descriptor_count = @intCast(pixel_samplers.len),
                .stage_flags = .{ .vertex = true, .fragment = true, .compute = true },
                .p_immutable_samplers = pixel_samplers.ptr,
            };
            sampler_bindings_count += 1;
        }

        const sampler_layout_info: vk.DescriptorSetLayoutCreateInfo = .{
            .flags = .{
                .descriptor_buffer_ext = true,
                .embedded_immutable_samplers_ext = true,
            },
            .binding_count = sampler_bindings_count,
            .p_bindings = &sampler_bindings,
        };
        return try d.handle.createDescriptorSetLayout(&sampler_layout_info, null);
    }

    fn createPipelineLayout(
        d: *Device,
        sampler_set_layout: vk.DescriptorSetLayout,
        push_constant_ranges: []const vk.PushConstantRange,
    ) !vk.PipelineLayout {
        const set_layouts = [_]vk.DescriptorSetLayout{
            d.texture_heap_set_layout,
            sampler_set_layout,
        };
        const pipeline_layout_info: vk.PipelineLayoutCreateInfo = .{
            .push_constant_range_count = @intCast(push_constant_ranges.len),
            .p_push_constant_ranges = push_constant_ranges.ptr,
            .set_layout_count = set_layouts.len,
            .p_set_layouts = &set_layouts,
        };
        return try d.handle.createPipelineLayout(&pipeline_layout_info, null);
    }
};

pub fn Object(T: type) type {
    return extern struct {
        header: *anyopaque,
        body_bytes: [@sizeOf(T)]u8 align(@alignOf(T)),

        pub fn body(handle: *@This()) *T {
            return @ptrCast(&handle.body_bytes);
        }

        pub fn set(handle: *@This(), table: *anyopaque, body_value: T) void {
            handle.header = table;
            handle.body().* = body_value;
        }
    };
}

const wrap_sf_allocator = struct {
    fn alloc(user_data: *anyopaque, len: usize, alignment: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
        _ = ret_addr;
        const sf_gpa: *sf.HostAllocator = @ptrCast(@alignCast(user_data));
        return sf_gpa.alloc(sf_gpa.user_data, len, alignment.toByteUnits());
    }
    fn remap(user_data: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
        _ = ret_addr;
        const sf_gpa: *sf.HostAllocator = @ptrCast(@alignCast(user_data));
        return sf_gpa.remap(sf_gpa.user_data, memory.ptr, memory.len, alignment.toByteUnits(), new_len);
    }
    fn free(user_data: *anyopaque, memory: []u8, alignment: std.mem.Alignment, ret_addr: usize) void {
        _ = ret_addr;
        const sf_gpa: *sf.HostAllocator = @ptrCast(@alignCast(user_data));
        return sf_gpa.free(sf_gpa.user_data, memory.ptr, memory.len, alignment.toByteUnits());
    }

    const vtable: *const std.mem.Allocator.VTable = &.{
        .alloc = wrap_sf_allocator.alloc,
        .remap = wrap_sf_allocator.remap,
        .free = wrap_sf_allocator.free,
        .resize = std.mem.Allocator.noResize,
    };
};

fn debugCallback(
    message_severity: vk.DebugUtilsMessageSeverityFlagsEXT,
    message_types: vk.DebugUtilsMessageTypeFlagsEXT,
    p_callback_data: ?*const vk.DebugUtilsMessengerCallbackDataEXT,
    p_user_data: ?*anyopaque,
) callconv(vk.vulkan_call_conv) vk.Bool32 {
    _ = .{ message_types, p_user_data };
    const callback_data = p_callback_data orelse @panic("");
    const message = std.mem.span(callback_data.p_message orelse "no message");
    if (message_severity.error_ext) {
        std.log.err("Validation: {s}", .{message});
    } else if (message_severity.warning_ext) {
        std.log.warn("Validation: {s}", .{message});
    } else {
        std.log.info("Validation: {s}", .{message});
    }
    if (message_severity.error_ext or message_severity.warning_ext) {
        std.debug.dumpCurrentStackTrace(.{});
    }
    return .false;
}

pub export fn symbol(name: [*:0]const u8) callconv(sf.@"callconv") *const anyopaque {
    const map = symbol_map.map(.{
        .Instance = Object(Instance),
        .Adapter = Adapter,
        .Surface = Object(Surface),
        .Device = Object(Device),
        .Queue = Object(Queue),
        .Semaphore = Object(Semaphore),
        .Swapchain = Object(Swapchain),
        .CommandBuffer = Object(CommandBuffer),
        .DepthStencilState = Object(DepthStencilState),
        .Texture = Object(Texture),
        .Pipeline = Object(Pipeline),
    }, .{
        .adapterInfo = Instance.adapterInfo,
        .createSurfaceWin32 = Surface.createSurfaceWin32,
        .createSurfaceXlib = Surface.createSurfaceXlib,
        .destroySurface = Surface.destroy,
        .surfaceSupportedUsage = Device.surfaceSupportedUsage,
        .surfaceFormats = Device.surfaceFormats,
        .surfacePresentModes = Device.surfacePresentModes,
        .hostFromDevicePointer = Device.hostFromDevicePointer,
        .alloc = Device.alloc,
        .free = Device.free,
        .descriptorSizeAndHeapAlign = Texture.Descriptor.sizeAndHeapAlign,
        .storeDescriptor = Texture.Descriptor.storeDescriptor,
        .getQueue = Queue.getQueue,
        .startCommandRecording = Queue.startCommandRecording,
        .submit = Queue.submit,
        .submitAndSignal = Queue.submitAndSignal,
        .createSemaphore = Semaphore.create,
        .destroySemaphore = Semaphore.destroy,
        .waitSemaphore = Semaphore.wait,
        .createSwapchain = Swapchain.create,
        .destroySwapchain = Swapchain.destroy,
        .acquireBackBuffer = Swapchain.acquire,
        .present = Swapchain.present,
        .setActiveTextureHeap = CommandBuffer.setActiveTextureHeap,
        .setPipeline = CommandBuffer.setPipeline,
        .setDepthStencilState = CommandBuffer.setDepthStencilState,
        .dispatch = CommandBuffer.dispatch,
        .barrier = CommandBuffer.barrier,
        .copyTextureToBuffer = CommandBuffer.copyTextureToBuffer,
        .copyBufferToTexture = CommandBuffer.copyBufferToTexture,
        .beginRenderPass = CommandBuffer.beginRenderPass,
        .endRenderPass = CommandBuffer.endRenderPass,
        .draw = CommandBuffer.draw,
        .drawIndexed = CommandBuffer.drawIndexed,
        .drawIndexedInstanced = CommandBuffer.drawIndexedInstanced,
        .drawIndexedInstancedIndirect = CommandBuffer.drawIndexedInstancedIndirect,
        .textureSizeAndAlign = Texture.sizeAndAlign,
        .createTexture = Texture.create,
        .destroyTexture = Texture.destroy,
        .textureStorageDescriptor = Texture.storageDescriptor,
        .textureViewDescriptor = Texture.viewDescriptor,
        .createComputePipeline = Pipeline.createCompute,
        .createGraphicsPipeline = Pipeline.createGraphics,
        .destroyPipeline = Pipeline.destroy,
        .createDepthStencilState = DepthStencilState.create,
        .destroyDepthStencilState = DepthStencilState.destroy,
    });
    return map.get(std.mem.span(name)).?;
}
