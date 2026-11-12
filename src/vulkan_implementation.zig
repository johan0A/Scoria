const std = @import("std");
const build_options = @import("options");
const sc = @import("sc_minimal.zig");
const to_sc = @import("bridge.zig").to_sc;
const to_vk = @import("bridge.zig").to_vk;
const scir = @import("scir.zig");
const vk = @import("vulkan");
const VulkanLoader = @import("VulkanLoader.zig");
const symbol_map = @import("driver_symbol_map.zig");

pub const Instance = struct {
    handle: vk.InstanceProxy,
    loader: VulkanLoader,
    surface_support: SurfaceSupport,
    debug_messenger: vk.DebugUtilsMessengerEXT,
    sc_gpa: sc.HostAllocator,
    gpa: std.mem.Allocator,

    const SurfaceSupport = packed struct {
        surface: bool = false,
        win32: bool = false,
        xlib: bool = false,
        capabilities_2: bool = false,
        maintenance_1: bool = false,
    };

    pub fn create(host_allocator: ?*sc.HostAllocator) *Object(Instance) {
        return createInner(host_allocator) catch @panic("TODO");
    }
    fn createInner(host_allocator: ?*sc.HostAllocator) !*Object(Instance) {
        const instance_gpa: std.mem.Allocator = if (host_allocator) |ha| .{
            .ptr = ha,
            .vtable = wrap_sc_allocator.vtable,
        } else std.heap.smp_allocator;
        const instance_obj = try instance_gpa.create(Object(Instance));
        errdefer instance_gpa.destroy(instance_obj);

        const sc_gpa = &instance_obj.body().sc_gpa;
        if (host_allocator) |ha| sc_gpa.* = ha.*;
        const gpa: std.mem.Allocator = if (host_allocator != null) .{
            .ptr = sc_gpa,
            .vtable = wrap_sc_allocator.vtable,
        } else std.heap.smp_allocator;

        var arena_impl: std.heap.ArenaAllocator = .init(gpa);
        defer arena_impl.deinit();
        const arena = arena_impl.allocator();

        const loader: VulkanLoader = try .open();
        errdefer loader.close();
        const base_dispatch: vk.BaseWrapper = .load(loader.proc);

        var extensions: std.ArrayList([*:0]const u8) = .empty;
        var surface_support: SurfaceSupport = .{};
        const surface_extensions = .{
            .surface = vk.instance_extensions.khr_surface,
            .win32 = vk.instance_extensions.khr_win_32_surface,
            .xlib = vk.instance_extensions.khr_xlib_surface,
            .capabilities_2 = vk.instance_extensions.khr_get_surface_capabilities_2,
            .maintenance_1 = vk.instance_extensions.khr_surface_maintenance_1,
        };
        for (try base_dispatch.enumerateInstanceExtensionPropertiesAlloc(null, arena)) |available_extension| {
            const name = std.mem.sliceTo(&available_extension.extension_name, 0);
            inline for (comptime std.meta.fieldNames(SurfaceSupport)) |field_name| {
                const extension = @field(surface_extensions, field_name);
                if (std.mem.eql(u8, name, extension.name)) {
                    @field(surface_support, field_name) = true;
                    try extensions.append(arena, extension.name);
                }
            }
        }

        const validation_layer = "VK_LAYER_KHRONOS_validation";
        var enable_validation = build_options.validation_layers;
        if (enable_validation) {
            for (try base_dispatch.enumerateInstanceLayerPropertiesAlloc(arena)) |available_layer| {
                if (std.mem.eql(u8, std.mem.sliceTo(&available_layer.layer_name, 0), validation_layer)) break;
            } else {
                std.log.warn("vulkan validation layers unsupported", .{});
                enable_validation = false;
            }
        }
        if (enable_validation) try extensions.append(arena, vk.instance_extensions.ext_debug_utils.name);

        const instance_dispatch = try gpa.create(vk.InstanceWrapper);
        errdefer gpa.destroy(instance_dispatch);
        const instance_handle = try base_dispatch.createInstance(&.{
            .p_application_info = &.{
                .application_version = 0,
                .engine_version = 0,
                .api_version = vk.API_VERSION_1_3.toU32(),
            },
            .enabled_extension_count = @intCast(extensions.items.len),
            .pp_enabled_extension_names = extensions.items.ptr,
            .enabled_layer_count = @intFromBool(enable_validation),
            .pp_enabled_layer_names = &.{validation_layer},
        }, null);
        instance_dispatch.* = .load(instance_handle, base_dispatch.dispatch.vkGetInstanceProcAddr.?);
        const handle: vk.InstanceProxy = .init(instance_handle, instance_dispatch);
        errdefer handle.destroyInstance(null);

        const debug_messenger: vk.DebugUtilsMessengerEXT = if (enable_validation) try handle.createDebugUtilsMessengerEXT(&.{
            .message_severity = .{ .warning_ext = true, .error_ext = true },
            .message_type = .{ .general_ext = true, .validation_ext = true, .performance_ext = true },
            .pfn_user_callback = debugCallback,
        }, null) else .null;

        instance_obj.set(undefined, .{
            .handle = handle,
            .loader = loader,
            .surface_support = surface_support,
            .debug_messenger = debug_messenger,
            .sc_gpa = sc_gpa.*,
            .gpa = gpa,
        });
        return instance_obj;
    }

    pub fn destroyInstance(instance_obj: *Object(Instance)) void {
        const instance = instance_obj.body();
        if (instance.debug_messenger != .null) instance.handle.destroyDebugUtilsMessengerEXT(instance.debug_messenger, null);
        instance.handle.destroyInstance(null);
        instance.loader.close();
        instance.gpa.destroy(instance.handle.wrapper);
        instance.gpa.destroy(instance_obj);
    }

    pub fn enumerateAdapters(
        instance_obj: *Object(Instance),
        adapters_capacity: usize,
        adapters: ?[*]*Adapter,
        adapter_count: *usize,
    ) void {
        var arena_impl: std.heap.ArenaAllocator = .init(instance_obj.body().gpa);
        defer arena_impl.deinit();
        const compatible_adapters = compatibleAdapters(instance_obj.body(), arena_impl.allocator()) catch @panic("TODO");
        writeEnumeration(*Adapter, compatible_adapters, adapters_capacity, adapters, adapter_count);
    }
    fn compatibleAdapters(instance: *Instance, arena: std.mem.Allocator) ![]*Adapter {
        const physical_devices = try instance.handle.enumeratePhysicalDevicesAlloc(arena);
        var adapters: std.ArrayList(*Adapter) = try .initCapacity(arena, physical_devices.len);
        for (physical_devices) |physical_device| {
            const support: Adapter.Support = try .query(instance, physical_device, arena);
            if (support.compatible) {
                adapters.appendAssumeCapacity(.fromPhysicalDevice(physical_device));
            } else {
                const properties = instance.handle.getPhysicalDeviceProperties(physical_device);
                std.log.info("incompatible vulkan adapter: {s}", .{std.mem.sliceTo(&properties.device_name, 0)});
            }
        }
        return adapters.items;
    }

    pub fn adapterInfo(instance: *Object(Instance), adapter: *Adapter) sc.AdapterInfo {
        const properties = instance.body().handle.getPhysicalDeviceProperties(adapter.asPhysicalDevice());
        return .{
            .name = properties.device_name,
            .kind = to_sc.adapterKind(properties.device_type),
        };
    }
};

pub const Surface = struct {
    handle: vk.SurfaceKHR,
    supported_usage: sc.TextureUsage,
    formats: []sc.Format,
    present_modes: []sc.PresentMode,
    d: *Device,

    pub fn createSurfaceWin32(d: *Object(Device), desc: sc.SurfaceWin32Desc) *Object(Surface) {
        return createInner(d.body(), .{ .win32 = desc }) catch @panic("TODO");
    }

    pub fn createSurfaceXlib(d: *Object(Device), desc: sc.SurfaceXlibDesc) *Object(Surface) {
        return createInner(d.body(), .{ .xlib = desc }) catch @panic("TODO");
    }

    const Desc = union(enum) {
        win32: sc.SurfaceWin32Desc,
        xlib: sc.SurfaceXlibDesc,
    };
    fn createInner(d: *Device, desc: Desc) !*Object(Surface) {
        const instance = d.instance;
        var arena_impl: std.heap.ArenaAllocator = .init(d.gpa);
        defer arena_impl.deinit();
        const arena = arena_impl.allocator();

        const surface = try d.surfaces.create(d.gpa);
        errdefer d.surfaces.destroy(surface);

        const handle = switch (desc) {
            .win32 => |win32| if (!instance.surface_support.win32)
                return error.ExtensionNotPresent
            else
                try instance.handle.createWin32SurfaceKHR(&.{
                    .hinstance = @ptrCast(win32.hinstance),
                    .hwnd = @ptrCast(win32.hwnd),
                }, null),

            .xlib => |xlib| if (!instance.surface_support.xlib)
                return error.ExtensionNotPresent
            else
                try instance.handle.createXlibSurfaceKHR(&.{
                    .dpy = @ptrCast(xlib.display),
                    .window = @intCast(xlib.window),
                }, null),
        };
        errdefer instance.handle.destroySurfaceKHR(handle, null);

        const capabilities = try instance.handle.getPhysicalDeviceSurfaceCapabilitiesKHR(d.physical_device, handle);

        const vk_formats = try instance.handle.getPhysicalDeviceSurfaceFormatsAllocKHR(d.physical_device, handle, arena);
        var formats: std.ArrayList(sc.Format) = try .initCapacity(d.gpa, vk_formats.len);
        errdefer formats.deinit(d.gpa);
        for (vk_formats) |vk_format| {
            if (vk_format.color_space != .srgb_nonlinear_khr) continue;
            const format = to_sc.format(vk_format.format) orelse continue;
            if (format != .none) formats.appendAssumeCapacity(format);
        }

        const vk_present_modes = try instance.handle.getPhysicalDeviceSurfacePresentModesAllocKHR(d.physical_device, handle, arena);
        var present_modes: std.ArrayList(sc.PresentMode) = try .initCapacity(d.gpa, vk_present_modes.len);
        errdefer present_modes.deinit(d.gpa);
        for (vk_present_modes) |vk_present_mode| {
            present_modes.appendAssumeCapacity(to_sc.presentMode(vk_present_mode) orelse continue);
        }

        const formats_slice = try formats.toOwnedSlice(d.gpa);
        errdefer d.gpa.free(formats_slice);
        surface.set(d.table, .{
            .handle = handle,
            .supported_usage = to_sc.usageFlags(capabilities.supported_usage_flags),
            .formats = formats_slice,
            .present_modes = try present_modes.toOwnedSlice(d.gpa),
            .d = d,
        });
        return surface;
    }

    pub fn destroy(surface_obj: *Object(Surface)) void {
        const surface = surface_obj.body();
        const d = surface.d;
        d.instance.handle.destroySurfaceKHR(surface.handle, null);
        d.gpa.free(surface.formats);
        d.gpa.free(surface.present_modes);
        d.surfaces.destroy(surface_obj);
    }

    pub fn supportedUsage(surface: *Object(Surface)) sc.TextureUsage {
        return surface.body().supported_usage;
    }

    pub fn supportedFormats(
        surface: *Object(Surface),
        formats_capacity: usize,
        formats: ?[*]sc.Format,
        format_count: *usize,
    ) void {
        writeEnumeration(sc.Format, surface.body().formats, formats_capacity, formats, format_count);
    }

    pub fn presentModes(
        surface: *Object(Surface),
        present_modes_capacity: usize,
        present_modes: ?[*]sc.PresentMode,
        present_mode_count: *usize,
    ) void {
        writeEnumeration(sc.PresentMode, surface.body().present_modes, present_modes_capacity, present_modes, present_mode_count);
    }
};

pub const Adapter = opaque {
    comptime {
        std.debug.assert(@sizeOf(vk.PhysicalDevice) == @sizeOf(*Adapter));
    }

    const required_extensions = [_][*:0]const u8{
        vk.device_extensions.ext_descriptor_buffer.name,
        vk.device_extensions.ext_mutable_descriptor_type.name,
    };

    const Features = struct {
        core: vk.PhysicalDeviceFeatures2 = .{ .features = .{} },
        vk11: vk.PhysicalDeviceVulkan11Features = .{},
        vk12: vk.PhysicalDeviceVulkan12Features = .{},
        vk13: vk.PhysicalDeviceVulkan13Features = .{},
        descriptor_buffer: vk.PhysicalDeviceDescriptorBufferFeaturesEXT = .{},
        mutable_descriptor_type: vk.PhysicalDeviceMutableDescriptorTypeFeaturesEXT = .{},
        unified_image_layouts: vk.PhysicalDeviceUnifiedImageLayoutsFeaturesKHR = .{},
        dynamic_rendering_local_read: vk.PhysicalDeviceDynamicRenderingLocalReadFeaturesKHR = .{},
        present_id_2: vk.PhysicalDevicePresentId2FeaturesKHR = .{},
        present_wait_2: vk.PhysicalDevicePresentWait2FeaturesKHR = .{},
        swapchain_maintenance_1: vk.PhysicalDeviceSwapchainMaintenance1FeaturesKHR = .{},

        const Optional = struct {
            unified_image_layouts: bool,
            dynamic_rendering_local_read: bool,
            present_id_2: bool,
            present_wait_2: bool,
            swapchain_maintenance_1: bool,
        };
        const optional_extensions = .{
            .unified_image_layouts = vk.device_extensions.khr_unified_image_layouts,
            .dynamic_rendering_local_read = vk.device_extensions.khr_dynamic_rendering_local_read,
            .present_id_2 = vk.device_extensions.khr_present_id_2,
            .present_wait_2 = vk.device_extensions.khr_present_wait_2,
            .swapchain_maintenance_1 = vk.device_extensions.khr_swapchain_maintenance_1,
        };

        const required: Features = .{
            .core = .{ .features = .{
                .shader_int_64 = .true,
                .shader_int_16 = .true,
                .sampler_anisotropy = .true,
                .independent_blend = .true,
                .multi_draw_indirect = .true,
            } },
            .vk11 = .{
                .shader_draw_parameters = .true,
                .storage_buffer_16_bit_access = .true,
                .uniform_and_storage_buffer_16_bit_access = .true,
            },
            .vk12 = .{
                .buffer_device_address = .true,
                .runtime_descriptor_array = .true,
                .descriptor_binding_partially_bound = .true,
                .descriptor_binding_variable_descriptor_count = .true,
                .descriptor_binding_sampled_image_update_after_bind = .true,
                .descriptor_binding_storage_buffer_update_after_bind = .true,
                .scalar_block_layout = .true,
                .sampler_filter_minmax = .true,
                .timeline_semaphore = .true,
                .shader_float_16 = .true,
                .shader_int_8 = .true,
                .storage_buffer_8_bit_access = .true,
                .uniform_and_storage_buffer_8_bit_access = .true,
            },
            .vk13 = .{
                .dynamic_rendering = .true,
                .synchronization_2 = .true,
            },
            .descriptor_buffer = .{ .descriptor_buffer = .true },
            .mutable_descriptor_type = .{ .mutable_descriptor_type = .true },
        };

        fn link(features: *Features, optional: Optional) *vk.PhysicalDeviceFeatures2 {
            var next: *?*anyopaque = &features.core.p_next;
            inline for (comptime std.meta.fieldNames(Features)[1..]) |field_name| {
                if (!@hasField(Optional, field_name) or @field(optional, field_name)) {
                    next.* = &@field(features, field_name);
                    next = &@field(features, field_name).p_next;
                }
            }
            next.* = null;
            return &features.core;
        }

        fn isSubset(this: Features, other: Features) bool {
            return isSubsetInner(this, other);
        }
        fn isSubsetInner(this: anytype, other: @TypeOf(this)) bool {
            inline for (comptime std.meta.fieldNames(@TypeOf(this))) |field_name| {
                const FieldType = @FieldType(@TypeOf(this), field_name);
                const wanted_field = @field(this, field_name);
                const supported_field = @field(other, field_name);
                if (FieldType == vk.Bool32) {
                    if (wanted_field == .true and supported_field == .false) return false;
                } else if (@typeInfo(FieldType) == .@"struct") {
                    if (!isSubsetInner(wanted_field, supported_field)) return false;
                }
            }
            return true;
        }
    };

    const Support = struct {
        compatible: bool,
        swapchain: bool,
        optional: Features.Optional,

        fn query(instance: *Instance, physical_device: vk.PhysicalDevice, arena: std.mem.Allocator) !Support {
            const properties = instance.handle.getPhysicalDeviceProperties(physical_device);
            const extensions = try instance.handle.enumerateDeviceExtensionPropertiesAlloc(physical_device, null, arena);
            const incompatible: Support = .{ .compatible = false, .swapchain = false, .optional = undefined };

            if (properties.api_version < vk.API_VERSION_1_3.toU32()) return incompatible;
            for (required_extensions) |name| {
                if (!hasExtension(extensions, std.mem.span(name))) return incompatible;
            }

            var available: Features.Optional = undefined;
            inline for (comptime std.meta.fieldNames(Features.Optional)) |field_name| {
                @field(available, field_name) = hasExtension(extensions, @field(Features.optional_extensions, field_name).name);
            }

            var supported: Features = .{};
            instance.handle.getPhysicalDeviceFeatures2(physical_device, supported.link(available));

            var optional: Features.Optional = undefined;
            inline for (comptime std.meta.fieldNames(Features.Optional)) |field_name| {
                @field(optional, field_name) = @field(available, field_name) and
                    @field(@field(supported, field_name), field_name) == .true;
            }

            const queue_families = try instance.handle.getPhysicalDeviceQueueFamilyPropertiesAlloc(physical_device, arena);
            const has_graphics_queue = for (queue_families) |family| {
                if (family.queue_flags.graphics and family.queue_flags.compute) break true;
            } else false;

            const swapchain = instance.surface_support.surface and hasExtension(extensions, vk.device_extensions.khr_swapchain.name);
            optional.present_id_2 = optional.present_id_2 and swapchain and instance.surface_support.capabilities_2;
            optional.present_wait_2 = optional.present_wait_2 and optional.present_id_2;
            optional.swapchain_maintenance_1 = optional.swapchain_maintenance_1 and swapchain and instance.surface_support.maintenance_1;

            return .{
                .compatible = has_graphics_queue and Features.isSubset(Features.required, supported),
                .swapchain = swapchain,
                .optional = optional,
            };
        }
        fn hasExtension(extensions: []const vk.ExtensionProperties, name: []const u8) bool {
            return for (extensions) |extension| {
                if (std.mem.eql(u8, std.mem.sliceTo(&extension.extension_name, 0), name)) break true;
            } else false;
        }
    };

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
    gpa: std.mem.Allocator,
    table: *anyopaque,

    queues: [max_queue_count]Object(Queue),
    queue_count: u8,
    queue_index_from_kind: std.EnumArray(sc.QueueKind, u8),

    heap: AddressMap,

    memory_properties: vk.PhysicalDeviceMemoryProperties,
    has_host_visible_device_local: bool,
    /// memory types able to hold most common textures, `.device_local` allocations must use one of them
    image_memory_type_bits: u32,
    descriptor_buffer_properties: vk.PhysicalDeviceDescriptorBufferPropertiesEXT,
    swapchain_supported: bool,
    optional_features: Adapter.Features.Optional,

    texture_heap_set_layout: vk.DescriptorSetLayout,

    /// pending undefined to general layout transitions
    pending_texture_inits: std.array_hash_map.Auto(vk.Image, sc.TextureDesc),
    /// orders texture initializations between queues
    texture_init_timeline: struct {
        semaphore: vk.Semaphore,
        value: u64,
    },

    surfaces: std.heap.MemoryPool(Object(Surface)),
    timelines: std.heap.MemoryPool(Object(Timeline)),
    swapchains: std.heap.MemoryPool(Object(Swapchain)),
    command_buffers: std.heap.MemoryPool(Object(CommandBuffer)),
    textures: std.heap.MemoryPool(Object(Texture)),
    pipelines: std.heap.MemoryPool(Object(Pipeline)),
    depth_stencil_states: std.heap.MemoryPool(Object(DepthStencilState)),

    const max_queue_count = @typeInfo(sc.QueueKind).@"enum".field_names.len;

    const AddressMap = struct {
        entries: std.ArrayList(Entry),

        const Entry = struct {
            buffer: vk.Buffer,
            memory: vk.DeviceMemory,
            size: vk.DeviceSize,
            device_addr: sc.DeviceAddress,
            host_addr: ?usize,

            fn destroy(entry: Entry, device: vk.DeviceProxy) void {
                device.destroyBuffer(entry.buffer, null);
                device.freeMemory(entry.memory, null);
            }
        };

        fn entryAndOffsetFromAddr(map: *const AddressMap, device_addr: sc.DeviceAddress) struct { Entry, vk.DeviceSize } {
            const entry = map.entries.items[map.indexFromAddr(device_addr)];
            return .{ entry, device_addr - entry.device_addr };
        }

        fn indexFromAddr(map: *const AddressMap, device_addr: sc.DeviceAddress) usize {
            return std.sort.upperBound(Entry, map.entries.items, device_addr, order) - 1;
        }

        fn insert(map: *AddressMap, gpa: std.mem.Allocator, entry: Entry) !void {
            const index = std.sort.upperBound(Entry, map.entries.items, entry.device_addr, order);
            try map.entries.insert(gpa, index, entry);
        }

        fn order(device_addr: sc.DeviceAddress, entry: Entry) std.math.Order {
            return std.math.order(device_addr, entry.device_addr);
        }
    };

    pub fn create(instance: *Object(Instance), adapter: *Adapter) *Object(Device) {
        return createInner(instance.body(), instance.header, adapter) catch @panic("TODO");
    }
    fn createInner(instance: *Instance, table: *anyopaque, adapter: *Adapter) !*Object(Device) {
        const gpa = instance.gpa;
        const physical_device = adapter.asPhysicalDevice();
        var arena_impl: std.heap.ArenaAllocator = .init(gpa);
        defer arena_impl.deinit();
        const arena = arena_impl.allocator();

        const support: Adapter.Support = try .query(instance, physical_device, arena);
        if (!support.compatible) return error.FeatureNotPresent;

        const d_obj = try gpa.create(Object(Device));
        errdefer gpa.destroy(d_obj);

        // graphics queues must also support compute
        const family_properties = try instance.handle.getPhysicalDeviceQueueFamilyPropertiesAlloc(physical_device, arena);
        const graphics_family: u32 = for (family_properties, 0..) |family, i| {
            if (family.queue_flags.graphics and family.queue_flags.compute) break @intCast(i);
        } else return error.NoGraphicQueue; // TODO: when can this happen?
        const compute_family: u32 = for (family_properties, 0..) |family, i| {
            if (family.queue_flags.compute and !family.queue_flags.graphics) break @intCast(i);
        } else graphics_family;
        const transfer_family: u32 = for (family_properties, 0..) |family, i| {
            if (family.queue_flags.transfer and !family.queue_flags.graphics and !family.queue_flags.compute) break @intCast(i);
        } else compute_family;
        const family_from_kind: std.EnumArray(sc.QueueKind, u32) = .init(.{
            .graphics = graphics_family,
            .compute = compute_family,
            .transfer = transfer_family,
        });

        var queue_infos: [max_queue_count]vk.DeviceQueueCreateInfo = undefined;
        var queue_count: u8 = 0;
        var queue_index_from_kind: std.EnumArray(sc.QueueKind, u8) = undefined;
        for (std.enums.values(sc.QueueKind)) |kind| {
            const family = family_from_kind.get(kind);
            const index = for (queue_infos[0..queue_count], 0..) |queue_info, i| {
                if (queue_info.queue_family_index == family) break i;
            } else index: {
                queue_infos[queue_count] = .{ .queue_family_index = family, .queue_count = 1, .p_queue_priorities = &.{1} };
                queue_count += 1;
                break :index queue_count - 1;
            };
            queue_index_from_kind.set(kind, @intCast(index));
        }

        var features = Adapter.Features.required;
        var extensions_buffer: [16][*:0]const u8 = undefined;
        var extensions: std.ArrayList([*:0]const u8) = .initBuffer(&extensions_buffer);
        extensions.appendSliceAssumeCapacity(&Adapter.required_extensions);
        if (support.swapchain) extensions.appendAssumeCapacity(vk.device_extensions.khr_swapchain.name);
        inline for (comptime std.meta.fieldNames(Adapter.Features.Optional)) |field_name| {
            @field(@field(features, field_name), field_name) = .true;
            if (@field(support.optional, field_name)) {
                extensions.appendAssumeCapacity(@field(Adapter.Features.optional_extensions, field_name).name);
            }
        }

        const device_dispatch = try gpa.create(vk.DeviceWrapper);
        errdefer gpa.destroy(device_dispatch);
        const device_handle = try instance.handle.createDevice(physical_device, &.{
            .p_next = features.link(support.optional),
            .queue_create_info_count = queue_count,
            .p_queue_create_infos = &queue_infos,
            .enabled_extension_count = @intCast(extensions.items.len),
            .pp_enabled_extension_names = extensions.items.ptr,
        }, null);
        device_dispatch.* = .load(device_handle, instance.handle.wrapper.dispatch.vkGetDeviceProcAddr.?);
        const handle: vk.DeviceProxy = .init(device_handle, device_dispatch);
        errdefer handle.destroyDevice(null);

        const texture_heap_set_layout = layout: {
            var bindings = [_]vk.DescriptorSetLayoutBinding{.{
                .binding = 0,
                .descriptor_type = .mutable_ext,
                .descriptor_count = 0,
                .stage_flags = .{ .vertex = true, .fragment = true, .compute = true },
                .p_immutable_samplers = null,
            }};
            const allowed_types: []const vk.DescriptorType = &.{ .storage_image, .sampled_image };
            const mutable_info: vk.MutableDescriptorTypeCreateInfoEXT = .{
                .mutable_descriptor_type_list_count = 1,
                .p_mutable_descriptor_type_lists = &.{.{
                    .descriptor_type_count = allowed_types.len,
                    .p_descriptor_types = allowed_types.ptr,
                }},
            };
            const binding_flags_info: vk.DescriptorSetLayoutBindingFlagsCreateInfo = .{
                .p_next = &mutable_info,
                .binding_count = 1,
                .p_binding_flags = &.{.{ .partially_bound = true, .variable_descriptor_count = true }},
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
            break :layout try handle.createDescriptorSetLayout(&layout_info, null);
        };
        errdefer handle.destroyDescriptorSetLayout(texture_heap_set_layout, null);

        var queues: [max_queue_count]Object(Queue) = undefined;
        var initialized_queue_count: usize = 0;
        errdefer for (queues[0..initialized_queue_count]) |*queue| {
            handle.destroySemaphore(queue.body().timeline, null);
            handle.destroyCommandPool(queue.body().command_pool, null);
        };
        for (queues[0..queue_count], queue_infos[0..queue_count]) |*queue, queue_info| {
            const timeline = try Timeline.createTimeline(handle, 0);
            errdefer handle.destroySemaphore(timeline, null);
            queue.set(table, .{
                .handle = handle.getDeviceQueue(queue_info.queue_family_index, 0),
                .family = queue_info.queue_family_index,
                .timeline = timeline,
                .last_submitted = 0,
                .command_pool = try handle.createCommandPool(&.{
                    .flags = .{ .transient = true, .reset_command_buffer = true },
                    .queue_family_index = queue_info.queue_family_index,
                }, null),
                .pending_command_buffers = .empty,
                .free_command_buffers = .empty,
                .pending_acquires = .empty,
                .d = d_obj.body(),
            });
            initialized_queue_count += 1;
        }

        const memory_properties = instance.handle.getPhysicalDeviceMemoryProperties(physical_device);

        var image_memory_type_bits: u32 = std.math.maxInt(u32);
        for ([_]sc.TextureDesc{
            .{ .extent = .{ .width = 16, .height = 16, .depth = 1 }, .format = .rgba8_unorm, .usage = .{ .sampled = true, .color_attachment = true } },
            .{ .extent = .{ .width = 16, .height = 16, .depth = 1 }, .format = .depth32_float, .usage = .{ .sampled = true, .depth_stencil_attachment = true } },
        }) |desc| {
            image_memory_type_bits &= Texture.memoryRequirements(handle, desc).memory_type_bits;
        }

        var descriptor_buffer_properties = std.mem.zeroInit(vk.PhysicalDeviceDescriptorBufferPropertiesEXT, .{});
        var properties: vk.PhysicalDeviceProperties2 = .{ .p_next = &descriptor_buffer_properties, .properties = undefined };
        instance.handle.getPhysicalDeviceProperties2(physical_device, &properties);

        d_obj.set(table, .{
            .handle = handle,
            .instance = instance,
            .physical_device = physical_device,
            .gpa = gpa,
            .table = table,

            .queues = queues,
            .queue_count = queue_count,
            .queue_index_from_kind = queue_index_from_kind,

            .heap = .{ .entries = .empty },

            .memory_properties = memory_properties,
            .has_host_visible_device_local = for (memory_properties.memory_types[0..memory_properties.memory_type_count]) |memory_type| {
                const flags = memory_type.property_flags;
                // heuristic to check if ReBAR is on
                if (flags.device_local and flags.host_visible and
                    memory_properties.memory_heaps[memory_type.heap_index].size > 256 * 1024 * 1024)
                    break true;
            } else false,
            .image_memory_type_bits = image_memory_type_bits,
            .descriptor_buffer_properties = descriptor_buffer_properties,
            .swapchain_supported = support.swapchain,
            .optional_features = support.optional,

            .texture_heap_set_layout = texture_heap_set_layout,

            .pending_texture_inits = .empty,
            .texture_init_timeline = .{
                .semaphore = try Timeline.createTimeline(handle, 0),
                .value = 0,
            },

            .surfaces = .empty,
            .timelines = .empty,
            .swapchains = .empty,
            .command_buffers = .empty,
            .textures = .empty,
            .pipelines = .empty,
            .depth_stencil_states = .empty,
        });
        return d_obj;
    }

    pub fn destroy(d_obj: *Object(Device)) void {
        const d = d_obj.body();
        const gpa = d.gpa;
        d.handle.deviceWaitIdle() catch {};

        if (d.heap.entries.items.len != 0) std.log.warn("destroying a device with {d} live allocations", .{d.heap.entries.items.len});
        for (d.heap.entries.items) |entry| entry.destroy(d.handle);
        d.heap.entries.deinit(gpa);

        for (d.queues[0..d.queue_count]) |*queue_obj| {
            const queue = queue_obj.body();
            d.handle.destroySemaphore(queue.timeline, null);
            d.handle.destroyCommandPool(queue.command_pool, null);
            queue.free_command_buffers.deinit(gpa);
            queue.pending_command_buffers.deinit(gpa);
            queue.pending_acquires.deinit(gpa);
        }
        d.handle.destroySemaphore(d.texture_init_timeline.semaphore, null);
        d.handle.destroyDescriptorSetLayout(d.texture_heap_set_layout, null);
        d.handle.destroyDevice(null);
        gpa.destroy(d.handle.wrapper);

        d.pending_texture_inits.deinit(gpa);
        d.surfaces.deinit(gpa);
        d.timelines.deinit(gpa);
        d.swapchains.deinit(gpa);
        d.command_buffers.deinit(gpa);
        d.textures.deinit(gpa);
        d.pipelines.deinit(gpa);
        d.depth_stencil_states.deinit(gpa);
        gpa.destroy(d_obj);
    }

    pub fn hostFromDevicePointer(d: *Object(Device), ptr: sc.DeviceAddress) *anyopaque {
        const entry, const offset = d.body().heap.entryAndOffsetFromAddr(ptr);
        return @ptrFromInt(entry.host_addr.? + offset);
    }

    pub fn alloc(
        d: *Object(Device),
        size: usize,
        alignment: usize,
        memory: sc.MemoryKind,
        mapped_memory: *sc.HostDeviceAddress,
    ) !void {
        mapped_memory.* = allocInner(d.body(), size, .fromByteUnits(alignment), memory) catch |err| return switch (err) {
            error.InvalidExternalHandle => unreachable,
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
        size: usize,
        alignment: std.mem.Alignment,
        memory: sc.MemoryKind,
    ) !sc.HostDeviceAddress {
        std.debug.assert(size > 0);

        var families: [max_queue_count]u32 = undefined;
        for (d.queues[0..d.queue_count], families[0..d.queue_count]) |*queue, *family| family.* = queue.body().family;
        const concurrent = d.queue_count > 1;
        var buffer_info: vk.BufferCreateInfo = .{
            .size = size,
            .usage = to_vk.bufferUsage(memory),
            .sharing_mode = if (concurrent) .concurrent else .exclusive,
            .queue_family_index_count = if (concurrent) d.queue_count else 0,
            .p_queue_family_indices = &families,
        };

        // buffers are only aligned to their own requirement, a bigger alignment is reached by padding the buffer
        var unpadded_requirements: vk.MemoryRequirements2 = .{ .memory_requirements = undefined };
        d.handle.getDeviceBufferMemoryRequirements(&.{ .p_create_info = &buffer_info }, &unpadded_requirements);
        const buffer_alignment = unpadded_requirements.memory_requirements.alignment;
        if (buffer_alignment < alignment.toByteUnits()) buffer_info.size += alignment.toByteUnits() - buffer_alignment;

        const buffer = try d.handle.createBuffer(&buffer_info, null);
        errdefer d.handle.destroyBuffer(buffer, null);
        const requirements = d.handle.getBufferMemoryRequirements(buffer);

        const memory_type_bits = requirements.memory_type_bits & switch (memory) {
            .device_local => d.image_memory_type_bits,
            .upload, .readback => std.math.maxInt(u32),
        };
        const host_visible: vk.MemoryPropertyFlags = .{ .host_visible = true, .host_coherent = true };
        const properties_by_preference: []const vk.MemoryPropertyFlags = switch (memory) {
            .upload => if (d.has_host_visible_device_local) &.{ host_visible.merge(.{ .device_local = true }), host_visible } else &.{host_visible},
            .device_local => &.{.{ .device_local = true }},
            .readback => &.{ host_visible.merge(.{ .host_cached = true }), host_visible },
        };
        const memory_type_bit_set: std.bit_set.Integer(32) = .{ .mask = memory_type_bits };
        const memory_type_index: u32 = find: for (properties_by_preference) |properties| {
            for (d.memory_properties.memory_types[0..d.memory_properties.memory_type_count], 0..) |memory_type, i| {
                if (memory_type_bit_set.isSet(i) and
                    memory_type.property_flags.contains(properties)) break :find @intCast(i);
            }
        } else return error.OutOfDeviceMemory;

        const allocate_flags: vk.MemoryAllocateFlagsInfo = .{ .flags = .{ .device_address = true }, .device_mask = 0 };
        const device_memory = try d.handle.allocateMemory(&.{
            .p_next = &allocate_flags,
            .allocation_size = requirements.size,
            .memory_type_index = memory_type_index,
        }, null);
        errdefer d.handle.freeMemory(device_memory, null);
        try d.handle.bindBufferMemory(buffer, device_memory, 0);

        const entry: AddressMap.Entry = .{
            .buffer = buffer,
            .memory = device_memory,
            .size = buffer_info.size,
            .device_addr = d.handle.getBufferDeviceAddress(&.{ .buffer = buffer }),
            .host_addr = switch (memory) {
                .upload, .readback => @intFromPtr(try d.handle.mapMemory(device_memory, 0, vk.WHOLE_SIZE, .{})),
                .device_local => null,
            },
        };
        try d.heap.insert(d.gpa, entry);

        const offset = std.mem.alignForward(u64, entry.device_addr, alignment.toByteUnits()) - entry.device_addr;
        std.debug.assert(offset + size <= entry.size);
        return .{
            .device = entry.device_addr + offset,
            .host = if (entry.host_addr) |host_addr| @ptrFromInt(host_addr + offset) else undefined,
        };
    }

    pub fn free(d_obj: *Object(Device), ptr: sc.DeviceAddress) void {
        const d = d_obj.body();
        d.heap.entries.orderedRemove(d.heap.indexFromAddr(ptr)).destroy(d.handle);
    }
};

pub const Queue = struct {
    handle: vk.Queue,
    family: u32,
    /// signaled by every submission, with `last_submitted` as the latest value
    timeline: vk.Semaphore,
    last_submitted: u64,
    command_pool: vk.CommandPool,
    pending_command_buffers: std.ArrayList(PendingCommandBuffer),
    free_command_buffers: std.ArrayList(vk.CommandBuffer),
    /// swapchains whose back buffer acquire is waited on by the next submission
    pending_acquires: std.ArrayList(*Swapchain),
    d: *Device,

    const PendingCommandBuffer = struct {
        /// `Queue.timeline` value after which the command buffer can be reused.
        value: u64,
        command_buffer: vk.CommandBuffer,
    };

    pub fn getQueue(d_obj: *Object(Device), queue_kind: sc.QueueKind) *Object(Queue) {
        const d = d_obj.body();
        return &d.queues[d.queue_index_from_kind.get(queue_kind)];
    }

    pub fn startCommandRecording(queue: *Object(Queue), command_buffer: **Object(CommandBuffer)) !void {
        command_buffer.* = startCommandRecordingInner(queue.body()) catch |err| return switch (err) {
            error.OutOfMemory, error.OutOfHostMemory => error.OutOfMemory,
            error.OutOfDeviceMemory, error.Unknown => |e| e,
        };
    }
    fn startCommandRecordingInner(queue: *Queue) !*Object(CommandBuffer) {
        const d = queue.d;
        const command_buffer = try d.command_buffers.create(d.gpa);
        errdefer d.command_buffers.destroy(command_buffer);
        command_buffer.set(d.table, .{
            .handle = try queue.beginCommandBuffer(.{ .one_time_submit = true }),
            .queue = queue,
            .d = d,
        });
        return command_buffer;
    }

    pub fn submit(
        queue: *Object(Queue),
        command_buffer_count: usize,
        command_buffers: [*]const *Object(CommandBuffer),
    ) !void {
        submitInner(queue.body(), command_buffers[0..command_buffer_count], null) catch |err| return switch (err) {
            error.OutOfMemory, error.OutOfHostMemory => error.OutOfMemory,
            error.OutOfDeviceMemory, error.DeviceLost => |e| e,
            error.InvalidVideoStdParametersKHR, error.Unknown => error.Unknown,
        };
    }

    pub fn submitAndSignal(
        queue: *Object(Queue),
        command_buffer_count: usize,
        command_buffers: [*]const *Object(CommandBuffer),
        signal: sc.TimelinePoint,
    ) !void {
        submitInner(queue.body(), command_buffers[0..command_buffer_count], signal) catch |err| return switch (err) {
            error.OutOfMemory, error.OutOfHostMemory => error.OutOfMemory,
            error.OutOfDeviceMemory, error.DeviceLost => |e| e,
            error.InvalidVideoStdParametersKHR, error.Unknown => error.Unknown,
        };
    }

    /// command buffers are consumed on failure
    fn submitInner(queue: *Queue, command_buffers: []const *Object(CommandBuffer), signal: ?sc.TimelinePoint) !void {
        const d = queue.d;
        errdefer for (command_buffers) |command_buffer| {
            queue.releaseCommandBuffer(command_buffer.body().handle);
            d.command_buffers.destroy(command_buffer);
        };

        const submit_infos = try d.gpa.alloc(vk.CommandBufferSubmitInfo, command_buffers.len);
        defer d.gpa.free(submit_infos);
        for (command_buffers, submit_infos) |command_buffer, *submit_info| {
            std.debug.assert(command_buffer.body().queue == queue);
            try d.handle.endCommandBuffer(command_buffer.body().handle);
            submit_info.* = .{ .command_buffer = command_buffer.body().handle, .device_mask = 0 };
        }
        try queue.pending_command_buffers.ensureUnusedCapacity(d.gpa, command_buffers.len + 1);

        if (d.pending_texture_inits.count() != 0) {
            const barriers = try d.gpa.alloc(vk.ImageMemoryBarrier2, d.pending_texture_inits.count());
            defer d.gpa.free(barriers);
            for (barriers, d.pending_texture_inits.keys(), d.pending_texture_inits.values()) |*barrier, image, desc| {
                barrier.* = layoutTransition(image, desc, .undefined, .general);
            }

            const init_command_buffer = try queue.beginCommandBuffer(.{ .one_time_submit = true });
            errdefer queue.releaseCommandBuffer(init_command_buffer);
            d.handle.cmdPipelineBarrier2(init_command_buffer, &.{
                .image_memory_barrier_count = @intCast(barriers.len),
                .p_image_memory_barriers = barriers.ptr,
            });
            try d.handle.endCommandBuffer(init_command_buffer);

            const init_timeline = &d.texture_init_timeline;
            const signals = [2]vk.SemaphoreSubmitInfo{
                semaphoreSubmitInfo(queue.timeline, queue.last_submitted + 1),
                semaphoreSubmitInfo(init_timeline.semaphore, init_timeline.value + 1),
            };
            try d.handle.queueSubmit2(queue.handle, &.{.{
                .wait_semaphore_info_count = 1,
                .p_wait_semaphore_infos = &.{semaphoreSubmitInfo(init_timeline.semaphore, init_timeline.value)},
                .command_buffer_info_count = 1,
                .p_command_buffer_infos = &.{.{ .command_buffer = init_command_buffer, .device_mask = 0 }},
                .signal_semaphore_info_count = signals.len,
                .p_signal_semaphore_infos = &signals,
            }}, .null);
            queue.last_submitted += 1;
            init_timeline.value += 1;

            queue.pending_command_buffers.appendAssumeCapacity(.{ .value = queue.last_submitted, .command_buffer = init_command_buffer });
            d.pending_texture_inits.clearRetainingCapacity();
        }

        try queue.submitAfterAcquires(
            submit_infos,
            if (signal) |point| semaphoreSubmitInfo(Timeline.fromHandle(point.timeline).handle, point.value) else null,
        );

        for (command_buffers) |command_buffer| {
            queue.pending_command_buffers.appendAssumeCapacity(.{
                .value = queue.last_submitted,
                .command_buffer = command_buffer.body().handle,
            });
            d.command_buffers.destroy(command_buffer);
        }
    }

    /// submits after the pending swapchain acquires and texture initializations, signals `timeline`
    fn submitAfterAcquires(queue: *Queue, command_buffers: []const vk.CommandBufferSubmitInfo, signal: ?vk.SemaphoreSubmitInfo) !void {
        const d = queue.d;
        const acquires = queue.pending_acquires.items;
        const submit_infos = try d.gpa.alloc(vk.CommandBufferSubmitInfo, acquires.len + command_buffers.len);
        defer d.gpa.free(submit_infos);
        const waits = try d.gpa.alloc(vk.SemaphoreSubmitInfo, acquires.len + 1);
        defer d.gpa.free(waits);

        // waiting at the stages that can access the back buffer
        for (acquires, submit_infos[0..acquires.len], waits[0..acquires.len]) |swapchain, *submit_info, *wait| {
            submit_info.* = .{ .command_buffer = swapchain.images[swapchain.current].acquire_command_buffer, .device_mask = 0 };
            wait.* = .{ .semaphore = swapchain.acquire_semaphore.?.handle, .value = 0, .stage_mask = swapchain.acquire_stage, .device_index = 0 };
        }
        @memcpy(submit_infos[acquires.len..], command_buffers);
        waits[acquires.len] = semaphoreSubmitInfo(d.texture_init_timeline.semaphore, d.texture_init_timeline.value);

        const signals = [2]vk.SemaphoreSubmitInfo{ semaphoreSubmitInfo(queue.timeline, queue.last_submitted + 1), signal orelse undefined };
        try d.handle.queueSubmit2(queue.handle, &.{.{
            .wait_semaphore_info_count = @intCast(waits.len),
            .p_wait_semaphore_infos = waits.ptr,
            .command_buffer_info_count = @intCast(submit_infos.len),
            .p_command_buffer_infos = submit_infos.ptr,
            .signal_semaphore_info_count = if (signal == null) 1 else 2,
            .p_signal_semaphore_infos = &signals,
        }}, .null);
        queue.last_submitted += 1;

        for (acquires) |swapchain| swapchain.acquire_semaphore.?.reusable_value = queue.last_submitted;
        queue.pending_acquires.clearRetainingCapacity();
    }

    fn beginCommandBuffer(queue: *Queue, flags: vk.CommandBufferUsageFlags) !vk.CommandBuffer {
        const d = queue.d;
        queue.reclaimCommandBuffers();
        const command_buffer = queue.free_command_buffers.pop() orelse allocate: {
            var command_buffer: vk.CommandBuffer = undefined;
            try d.handle.allocateCommandBuffers(&.{
                .command_pool = queue.command_pool,
                .level = .primary,
                .command_buffer_count = 1,
            }, (&command_buffer)[0..1]);
            break :allocate command_buffer;
        };
        errdefer queue.releaseCommandBuffer(command_buffer);
        try d.handle.beginCommandBuffer(command_buffer, &.{ .flags = flags });
        return command_buffer;
    }
    fn reclaimCommandBuffers(queue: *Queue) void {
        const pending = &queue.pending_command_buffers;
        if (pending.items.len == 0) return;
        const completed = queue.d.handle.getSemaphoreCounterValue(queue.timeline) catch return;
        const reclaimable_count = for (pending.items, 0..) |item, i| {
            if (item.value > completed) break i;
        } else pending.items.len;
        for (pending.items[0..reclaimable_count]) |item| queue.releaseCommandBuffer(item.command_buffer);
        pending.replaceRangeAssumeCapacity(0, reclaimable_count, &.{});
    }

    fn releaseCommandBuffer(queue: *Queue, command_buffer: vk.CommandBuffer) void {
        queue.free_command_buffers.append(queue.d.gpa, command_buffer) catch {
            queue.d.handle.freeCommandBuffers(queue.command_pool, &.{command_buffer});
        };
    }
};

pub const Timeline = struct {
    handle: vk.Semaphore,
    d: *Device,

    pub fn create(d: *Object(Device), initial_value: u64, timeline: **Object(Timeline)) !void {
        timeline.* = createInner(d.body(), initial_value) catch |err| return switch (err) {
            error.OutOfMemory, error.OutOfHostMemory => error.OutOfMemory,
            error.OutOfDeviceMemory, error.Unknown => |e| e,
        };
    }
    fn createInner(d: *Device, initial_value: u64) !*Object(Timeline) {
        const timeline = try d.timelines.create(d.gpa);
        errdefer d.timelines.destroy(timeline);
        timeline.set(d.table, .{ .handle = try createTimeline(d.handle, initial_value), .d = d });
        return timeline;
    }

    pub fn destroy(timeline_obj: *Object(Timeline)) void {
        const timeline = timeline_obj.body();
        timeline.d.handle.destroySemaphore(timeline.handle, null);
        timeline.d.timelines.destroy(timeline_obj);
    }

    pub fn wait(point: sc.TimelinePoint) !void {
        const timeline = fromHandle(point.timeline);
        waitTimeline(timeline.d.handle, timeline.handle, point.value) catch |err| return switch (err) {
            error.OutOfHostMemory => error.OutOfMemory,
            error.OutOfDeviceMemory, error.Unknown, error.DeviceLost => |e| e,
        };
    }

    fn fromHandle(handle: *sc.Timeline) *Timeline {
        const timeline_obj: *Object(Timeline) = @ptrCast(@alignCast(handle));
        return timeline_obj.body();
    }

    fn createTimeline(device: vk.DeviceProxy, initial_value: u64) !vk.Semaphore {
        const type_info: vk.SemaphoreTypeCreateInfo = .{ .semaphore_type = .timeline, .initial_value = initial_value };
        return device.createSemaphore(&.{ .p_next = &type_info }, null);
    }

    fn waitTimeline(device: vk.DeviceProxy, semaphore: vk.Semaphore, value: u64) !void {
        _ = try device.waitSemaphores(&.{
            .semaphore_count = 1,
            .p_semaphores = &.{semaphore},
            .p_values = &.{value},
        }, std.math.maxInt(u64));
    }
};

pub const Swapchain = struct {
    handle: vk.SwapchainKHR,
    surface: vk.SurfaceKHR,
    desc: sc.SwapchainDesc,
    queue: *Queue,

    acquire_stage: vk.PipelineStageFlags2,
    present_wait_supported: bool,

    images: []Image,
    extent: sc.Extent2D,
    acquire_semaphores: []AcquireSemaphore,
    acquire_count: usize,

    acquire_semaphore: ?*AcquireSemaphore,
    current: u32,

    present_count: u64,
    retired: std.ArrayList(Retired),

    extent_last: sc.Extent2D,
    needs_recreate: bool,

    d: *Device,

    const Image = struct {
        texture: Object(Texture),
        /// undefined -> general
        acquire_command_buffer: vk.CommandBuffer,
        /// general -> present_src
        present_command_buffer: vk.CommandBuffer,
        /// binary, signaled by the present command buffer and waited by present
        present_semaphore: vk.Semaphore,
        /// signaled once the last present of the image released its resources, null without swapchain maintenance
        present_fence: vk.Fence,
    };

    const AcquireSemaphore = struct {
        /// binary.
        handle: vk.Semaphore,
        /// `queue.timeline` value after which the semaphore has been waited on and can be reused.
        reusable_value: u64,
    };

    const Retired = struct {
        handle: vk.SwapchainKHR,
        images: []Image,
        acquire_semaphores: []AcquireSemaphore,
        /// `queue.timeline` value after which no submission uses the swapchain
        value: u64,

        fn destroy(retired: Retired, queue: *Queue) void {
            const d = queue.d;
            deinitImages(queue, retired.images);
            for (retired.acquire_semaphores) |semaphore| d.handle.destroySemaphore(semaphore.handle, null);
            d.handle.destroySwapchainKHR(retired.handle, null);
            d.gpa.free(retired.images);
            d.gpa.free(retired.acquire_semaphores);
        }
    };

    pub fn create(
        queue: *Object(Queue),
        surface: *Object(Surface),
        desc: sc.SwapchainDesc,
        swapchain: **Object(Swapchain),
    ) !void {
        swapchain.* = createInner(queue.body(), surface.body(), desc) catch |err| return switch (err) {
            error.OutOfMemory, error.OutOfHostMemory => error.OutOfMemory,
            error.OutOfDeviceMemory, error.Unknown => |e| e,
            error.SurfaceLostKHR => error.SurfaceLost,
        };
    }
    fn createInner(queue: *Queue, surface: *Surface, desc: sc.SwapchainDesc) !*Object(Swapchain) {
        const d = queue.d;

        // TODO: move to adapter picking
        std.debug.assert(d.swapchain_supported and try queue.d.instance.handle.getPhysicalDeviceSurfaceSupportKHR(queue.d.physical_device, queue.family, surface.handle) == .true);

        const present_wait_supported = d.optional_features.present_wait_2 and supported: {
            var wait_capabilities: vk.SurfaceCapabilitiesPresentWait2KHR = .{ .present_wait_2_supported = .false };
            var id_capabilities: vk.SurfaceCapabilitiesPresentId2KHR = .{ .p_next = &wait_capabilities, .present_id_2_supported = .false };
            var capabilities: vk.SurfaceCapabilities2KHR = .{ .p_next = &id_capabilities, .surface_capabilities = undefined };
            try d.instance.handle.getPhysicalDeviceSurfaceCapabilities2KHR(d.physical_device, &.{ .surface = surface.handle }, &capabilities);
            break :supported id_capabilities.present_id_2_supported == .true and wait_capabilities.present_wait_2_supported == .true;
        };

        const swapchain = try d.swapchains.create(d.gpa);
        swapchain.set(d.table, .{
            .handle = .null,
            .surface = surface.handle,
            .desc = desc,
            .queue = queue,
            .acquire_stage = if (desc.usage.storage or desc.usage.sampled)
                .{ .all_commands = true }
            else
                .{ .color_attachment_output = true, .all_transfer = true },
            .present_wait_supported = present_wait_supported,
            .images = &.{},
            .extent = .{ .width = 0, .height = 0 },
            .acquire_semaphores = &.{},
            .acquire_count = 0,
            .acquire_semaphore = null,
            .current = undefined,
            .present_count = 0,
            .retired = .empty,
            .extent_last = .{ .width = 0, .height = 0 },
            .needs_recreate = true,
            .d = d,
        });
        return swapchain;
    }

    pub fn destroy(swapchain_obj: *Object(Swapchain)) void {
        const swapchain = swapchain_obj.body();
        const d = swapchain.d;
        const queue = swapchain.queue;
        d.handle.queueWaitIdle(queue.handle) catch {};
        if (std.mem.findScalar(*Swapchain, queue.pending_acquires.items, swapchain)) |i| _ = queue.pending_acquires.orderedRemove(i);
        for (swapchain.retired.items) |retired| retired.destroy(queue);
        swapchain.retired.deinit(d.gpa);
        Retired.destroy(.{
            .handle = swapchain.handle,
            .images = swapchain.images,
            .acquire_semaphores = swapchain.acquire_semaphores,
            .value = queue.last_submitted,
        }, queue);
        d.swapchains.destroy(swapchain_obj);
    }

    pub fn acquire(
        swapchain: *Object(Swapchain),
        extent: sc.Extent2D,
        back_buffer: *sc.BackBuffer,
    ) !void {
        back_buffer.* = acquireInner(swapchain.body(), extent) catch |err| return switch (err) {
            error.OutOfHostMemory, error.OutOfMemory => error.OutOfMemory,
            error.CompressionExhaustedEXT, error.OutOfDeviceMemory => error.OutOfDeviceMemory,
            error.FullScreenExclusiveModeLostEXT,
            error.NativeWindowInUseKHR,
            error.SurfaceLostKHR,
            => error.SurfaceLost,
            error.InvalidVideoStdParametersKHR,
            error.InvalidOpaqueCaptureAddressKHR,
            error.InitializationFailed,
            error.Unknown,
            => error.Unknown,
            error.DeviceLost, error.NoBackbuffer => |e| e,
        };
    }
    fn acquireInner(swapchain: *Swapchain, extent: sc.Extent2D) !sc.BackBuffer {
        const d = swapchain.d;
        const queue = swapchain.queue;
        std.debug.assert(swapchain.acquire_semaphore == null);
        try queue.pending_acquires.ensureUnusedCapacity(d.gpa, 1);

        const completed = try d.handle.getSemaphoreCounterValue(queue.timeline);
        var retired_index: usize = 0;
        while (retired_index < swapchain.retired.items.len) {
            const retired = swapchain.retired.items[retired_index];
            const presented = for (retired.images) |image| {
                if (image.present_fence != .null and try d.handle.getFenceStatus(image.present_fence) == .not_ready) break false;
            } else true;
            if (retired.value <= completed and presented) {
                retired.destroy(queue);
                _ = swapchain.retired.swapRemove(retired_index);
            } else retired_index += 1;
        }

        const extent_changed = !std.meta.eql(extent, swapchain.extent_last);
        swapchain.extent_last = extent;

        for (0..32) |_| {
            if (swapchain.needs_recreate or (extent_changed and !std.meta.eql(extent, swapchain.extent))) {
                const capabilities = try d.instance.handle.getPhysicalDeviceSurfaceCapabilitiesKHR(d.physical_device, swapchain.surface);
                const min_extent = capabilities.min_image_extent;
                const max_extent = capabilities.max_image_extent;
                const image_extent: vk.Extent2D = if (capabilities.current_extent.width != std.math.maxInt(u32)) capabilities.current_extent else .{
                    .width = std.math.clamp(extent.width, min_extent.width, max_extent.width),
                    .height = std.math.clamp(extent.height, min_extent.height, max_extent.height),
                };
                if (image_extent.width == 0 or image_extent.height == 0) return error.NoBackbuffer;

                var min_image_count = capabilities.min_image_count + 1;
                if (capabilities.max_image_count != 0) min_image_count = @min(min_image_count, capabilities.max_image_count);

                if (!d.optional_features.swapchain_maintenance_1) try d.handle.queueWaitIdle(queue.handle);
                const old_handle = swapchain.handle;
                try swapchain.retired.append(d.gpa, .{
                    .handle = old_handle,
                    .images = swapchain.images,
                    .acquire_semaphores = swapchain.acquire_semaphores,
                    .value = queue.last_submitted,
                });
                swapchain.handle = .null;
                swapchain.images = &.{};
                swapchain.acquire_semaphores = &.{};
                swapchain.handle = try d.handle.createSwapchainKHR(&.{
                    .flags = .{
                        .present_id_2_khr = swapchain.present_wait_supported,
                        .present_wait_2_khr = swapchain.present_wait_supported,
                    },
                    .surface = swapchain.surface,
                    .min_image_count = min_image_count,
                    .image_format = to_vk.format(swapchain.desc.format),
                    .image_color_space = .srgb_nonlinear_khr,
                    .image_extent = image_extent,
                    .image_array_layers = 1,
                    .image_usage = to_vk.usageFlags(swapchain.desc.usage),
                    .image_sharing_mode = .exclusive,
                    .queue_family_index_count = 0,
                    .p_queue_family_indices = null,
                    .pre_transform = capabilities.current_transform,
                    .composite_alpha = .{ .opaque_khr = true },
                    .present_mode = to_vk.presentMode(swapchain.desc.present_mode),
                    .clipped = .true,
                    .old_swapchain = old_handle,
                }, null);

                const vk_images = try d.handle.getSwapchainImagesAllocKHR(swapchain.handle, d.gpa);
                defer d.gpa.free(vk_images);

                const acquire_semaphores = try d.gpa.alloc(AcquireSemaphore, vk_images.len + 1);
                errdefer d.gpa.free(acquire_semaphores);
                @memset(acquire_semaphores, .{ .handle = .null, .reusable_value = 0 });
                errdefer for (acquire_semaphores) |semaphore| d.handle.destroySemaphore(semaphore.handle, null);
                for (acquire_semaphores) |*semaphore| semaphore.handle = try d.handle.createSemaphore(&.{}, null);

                const images = try d.gpa.alloc(Image, vk_images.len);
                errdefer d.gpa.free(images);
                var image_count: usize = 0;
                errdefer deinitImages(queue, images[0..image_count]);
                for (images, vk_images) |*image, vk_image| {
                    const texture_desc: sc.TextureDesc = .{
                        .extent = .{ .width = image_extent.width, .height = image_extent.height, .depth = 1 },
                        .format = swapchain.desc.format,
                        .usage = swapchain.desc.usage,
                    };
                    const default_view = try Texture.createView(d, vk_image, texture_desc, .{}, .{ .color = true });
                    errdefer d.handle.destroyImageView(default_view, null);
                    const present_semaphore = try d.handle.createSemaphore(&.{}, null);
                    errdefer d.handle.destroySemaphore(present_semaphore, null);
                    const present_fence: vk.Fence = if (d.optional_features.swapchain_maintenance_1)
                        try d.handle.createFence(&.{ .flags = .{ .signaled = true } }, null)
                    else
                        .null;
                    errdefer d.handle.destroyFence(present_fence, null);

                    var acquire_barrier = layoutTransition(vk_image, texture_desc, .undefined, .general);
                    acquire_barrier.src_stage_mask = swapchain.acquire_stage;
                    acquire_barrier.dst_stage_mask = swapchain.acquire_stage;
                    const acquire_command_buffer = try recordBarrier(queue, acquire_barrier);
                    errdefer queue.releaseCommandBuffer(acquire_command_buffer);
                    image.* = .{
                        .texture = undefined,
                        .acquire_command_buffer = acquire_command_buffer,
                        .present_command_buffer = try recordBarrier(queue, layoutTransition(vk_image, texture_desc, .general, .present_src_khr)),
                        .present_semaphore = present_semaphore,
                        .present_fence = present_fence,
                    };
                    image.texture.set(d.table, .{
                        .image = vk_image,
                        .desc = texture_desc,
                        .default_view = default_view,
                        .views = .empty,
                        .d = d,
                    });
                    image_count += 1;
                }

                swapchain.images = images;
                swapchain.extent = .{ .width = image_extent.width, .height = image_extent.height };
                swapchain.acquire_semaphores = acquire_semaphores;
                swapchain.present_count = 0;
                swapchain.needs_recreate = false;
            }

            const latency = swapchain.desc.frame_latency_max;
            if (swapchain.present_wait_supported and latency != 0 and swapchain.present_count >= latency) {
                _ = d.handle.waitForPresent2KHR(swapchain.handle, &.{
                    .present_id = swapchain.present_count + 1 - latency,
                    .timeout = 100 * std.time.ns_per_ms,
                }) catch |err| switch (err) {
                    error.OutOfDateKHR => {
                        swapchain.needs_recreate = true;
                        continue;
                    },
                    else => |e| return e,
                };
            }

            const acquire_semaphore = &swapchain.acquire_semaphores[swapchain.acquire_count % swapchain.acquire_semaphores.len];
            try Timeline.waitTimeline(d.handle, queue.timeline, acquire_semaphore.reusable_value);
            const result = d.handle.acquireNextImageKHR(
                swapchain.handle,
                std.math.maxInt(u64),
                acquire_semaphore.handle,
                .null,
            ) catch |err| switch (err) {
                error.OutOfDateKHR => {
                    swapchain.needs_recreate = true;
                    continue;
                },
                else => |e| return e,
            };
            if (result.result == .suboptimal_khr) swapchain.needs_recreate = true;
            swapchain.acquire_count += 1;
            swapchain.acquire_semaphore = acquire_semaphore;
            swapchain.current = result.image_index;
            queue.pending_acquires.appendAssumeCapacity(swapchain);
            return .{ .extent = swapchain.extent, .texture = @ptrCast(&swapchain.images[result.image_index].texture) };
        }
        return error.NoBackbuffer;
    }
    fn recordBarrier(queue: *Queue, barrier: vk.ImageMemoryBarrier2) !vk.CommandBuffer {
        const command_buffer = try queue.beginCommandBuffer(.{ .simultaneous_use = true });
        errdefer queue.releaseCommandBuffer(command_buffer);
        queue.d.handle.cmdPipelineBarrier2(command_buffer, &.{
            .image_memory_barrier_count = 1,
            .p_image_memory_barriers = &.{barrier},
        });
        try queue.d.handle.endCommandBuffer(command_buffer);
        return command_buffer;
    }

    pub fn present(swapchain: *Object(Swapchain)) !void {
        presentInner(swapchain.body()) catch |err| return switch (err) {
            error.OutOfMemory, error.OutOfHostMemory => error.OutOfMemory,
            error.PresentTimingQueueFullEXT, error.Unknown => error.Unknown,
            error.SurfaceLostKHR,
            error.FullScreenExclusiveModeLostEXT,
            => error.SurfaceLost,
            error.OutOfDeviceMemory, error.DeviceLost => |e| e,
        };
    }
    fn presentInner(swapchain: *Swapchain) !void {
        const d = swapchain.d;
        const queue = swapchain.queue;
        const image = &swapchain.images[swapchain.current];
        std.debug.assert(swapchain.acquire_semaphore != null);

        // also consumes the acquire when nothing was submitted since
        try queue.submitAfterAcquires(
            &.{.{ .command_buffer = image.present_command_buffer, .device_mask = 0 }},
            semaphoreSubmitInfo(image.present_semaphore, 0),
        );
        swapchain.acquire_semaphore = null;

        if (image.present_fence != .null) {
            _ = try d.handle.waitForFences(&.{image.present_fence}, .true, std.math.maxInt(u64));
            try d.handle.resetFences(&.{image.present_fence});
        }
        swapchain.present_count += 1;
        const fence_info: vk.SwapchainPresentFenceInfoKHR = .{ .swapchain_count = 1, .p_fences = &.{image.present_fence} };
        const fence_chain: ?*const anyopaque = if (image.present_fence != .null) &fence_info else null;
        const id_info: vk.PresentId2KHR = .{ .p_next = fence_chain, .swapchain_count = 1, .p_present_ids = &.{swapchain.present_count} };

        const result = d.handle.queuePresentKHR(queue.handle, &.{
            .p_next = if (swapchain.present_wait_supported) &id_info else fence_chain,
            .wait_semaphore_count = 1,
            .p_wait_semaphores = &.{image.present_semaphore},
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
        if (result == .suboptimal_khr) swapchain.needs_recreate = true;
    }

    fn deinitImages(queue: *Queue, images: []Image) void {
        const d = queue.d;
        for (images) |*image| {
            if (image.present_fence != .null) _ = d.handle.waitForFences(&.{image.present_fence}, .true, std.math.maxInt(u64)) catch {};
            image.texture.body().deinit(false);
            queue.releaseCommandBuffer(image.acquire_command_buffer);
            queue.releaseCommandBuffer(image.present_command_buffer);
            d.handle.destroySemaphore(image.present_semaphore, null);
            d.handle.destroyFence(image.present_fence, null);
        }
    }
};

pub const CommandBuffer = struct {
    handle: vk.CommandBuffer,
    queue: *Queue,

    pipeline_layout: vk.PipelineLayout = .null,
    pipeline_bind_point: vk.PipelineBindPoint = undefined,
    texture_heap_address: ?vk.DeviceAddress = null,
    in_render_pass: bool = false,

    d: *Device,

    pub fn setActiveTextureHeap(cb_obj: *Object(CommandBuffer), heap_address: sc.DeviceAddress) void {
        const cb = cb_obj.body();
        if (cb.texture_heap_address == heap_address) return;
        cb.d.handle.cmdBindDescriptorBuffersEXT(cb.handle, &.{.{
            .address = heap_address,
            .usage = .{ .resource_descriptor_buffer_ext = true },
        }});
        cb.texture_heap_address = heap_address;
        if (cb.pipeline_layout != .null) cb.setDescriptorBufferOffsets();
    }

    pub fn setPipeline(cb_obj: *Object(CommandBuffer), pipeline_obj: *Object(Pipeline)) void {
        const cb = cb_obj.body();
        const pipeline = pipeline_obj.body();
        cb.d.handle.cmdBindPipeline(cb.handle, pipeline.bind_point, pipeline.handle);
        cb.pipeline_layout = pipeline.pipeline_layout;
        cb.pipeline_bind_point = pipeline.bind_point;
        cb.d.handle.cmdBindDescriptorBufferEmbeddedSamplersEXT(cb.handle, pipeline.bind_point, pipeline.pipeline_layout, 1);
        if (cb.texture_heap_address != null) cb.setDescriptorBufferOffsets();
    }
    fn setDescriptorBufferOffsets(cb: *CommandBuffer) void {
        cb.d.handle.cmdSetDescriptorBufferOffsetsEXT(cb.handle, cb.pipeline_bind_point, cb.pipeline_layout, 0, &.{0}, &.{0});
    }

    pub fn setDepthStencilState(cb_obj: *Object(CommandBuffer), depth_stencil_state: *Object(DepthStencilState)) void {
        const cb = cb_obj.body();
        const desc = &depth_stencil_state.body().desc;

        cb.d.handle.cmdSetDepthTestEnable(cb.handle, .fromBool(desc.depth_mode.read or desc.depth_mode.write));
        cb.d.handle.cmdSetDepthWriteEnable(cb.handle, .fromBool(desc.depth_mode.write));
        cb.d.handle.cmdSetDepthCompareOp(cb.handle, if (desc.depth_mode.read) to_vk.compareOp(desc.depth_test) else .always);

        const depth_bias_enable = desc.depth_bias != 0 or desc.depth_bias_slope_factor != 0 or desc.depth_bias_clamp != 0;
        cb.d.handle.cmdSetDepthBiasEnable(cb.handle, .fromBool(depth_bias_enable));
        if (depth_bias_enable) {
            cb.d.handle.cmdSetDepthBias(cb.handle, desc.depth_bias, desc.depth_bias_clamp, desc.depth_bias_slope_factor);
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
    fn stencilIsNoop(stencil: sc.StencilDesc) bool {
        return stencil.@"test" == .always and stencil.pass_op == .keep and stencil.depth_fail_op == .keep;
    }
    fn setStencilFace(cb: *CommandBuffer, face: vk.StencilFaceFlags, stencil: sc.StencilDesc) void {
        cb.d.handle.cmdSetStencilOp(
            cb.handle,
            face,
            to_vk.stencilOp(stencil.fail_op),
            to_vk.stencilOp(stencil.pass_op),
            to_vk.stencilOp(stencil.depth_fail_op),
            to_vk.compareOp(stencil.@"test"),
        );
        cb.d.handle.cmdSetStencilReference(cb.handle, face, stencil.reference);
    }

    pub fn dispatch(
        cb_obj: *Object(CommandBuffer),
        data: sc.DeviceAddress,
        x: u32,
        y: u32,
        z: u32,
    ) void {
        const cb = cb_obj.body();
        cb.d.handle.cmdPushConstants(cb.handle, cb.pipeline_layout, .{ .compute = true }, 0, @sizeOf(vk.DeviceAddress), &data);
        cb.d.handle.cmdDispatch(cb.handle, x, y, z);
    }

    pub fn dispatchIndirect(cb_obj: *Object(CommandBuffer), data: sc.DeviceAddress, args: sc.DeviceAddress) void {
        const cb = cb_obj.body();
        cb.d.handle.cmdPushConstants(cb.handle, cb.pipeline_layout, .{ .compute = true }, 0, @sizeOf(vk.DeviceAddress), &data);
        const entry, const offset = cb.d.heap.entryAndOffsetFromAddr(args);
        cb.d.handle.cmdDispatchIndirect(cb.handle, entry.buffer, offset);
    }

    pub fn barrier(
        cb_obj: *Object(CommandBuffer),
        before: sc.Stage,
        after: sc.Stage,
        hazard: sc.Hazard,
    ) void {
        const cb = cb_obj.body();
        var dst_stage = to_vk.pipelineStage(after);
        if (hazard.draw_arguments) dst_stage.draw_indirect = true;
        if (hazard.depth_stencil) {
            dst_stage.early_fragment_tests = true;
            dst_stage.late_fragment_tests = true;
        }
        cb.d.handle.cmdPipelineBarrier2(cb.handle, &.{
            .dependency_flags = .{ .by_region = cb.in_render_pass },
            .memory_barrier_count = 1,
            .p_memory_barriers = &.{.{
                .src_stage_mask = to_vk.pipelineStage(before),
                .src_access_mask = .{ .memory_write = true },
                .dst_stage_mask = dst_stage,
                .dst_access_mask = .{
                    .memory_read = true,
                    .memory_write = true,
                    .descriptor_buffer_read_ext = hazard.descriptors,
                },
            }},
        });
    }

    /// 256 bytes is a typical optimal alignment for destination
    pub fn copyTextureToMemory(
        cb_obj: *Object(CommandBuffer),
        source_texture_obj: *Object(Texture),
        destination: sc.DeviceAddress,
        size: usize,
        desc: sc.TextureCopyDesc,
    ) void {
        const cb = cb_obj.body();
        const source_texture = source_texture_obj.body();
        const buffer, const region = bufferImageCopy(cb.d, source_texture, destination, size, desc);
        cb.d.handle.cmdCopyImageToBuffer2(cb.handle, &.{
            .src_image = source_texture.image,
            .src_image_layout = .general,
            .dst_buffer = buffer,
            .region_count = 1,
            .p_regions = &.{region},
        });
    }

    pub fn copyMemoryToTexture(
        cb_obj: *Object(CommandBuffer),
        source: sc.DeviceAddress,
        size: usize,
        destination_texture_obj: *Object(Texture),
        desc: sc.TextureCopyDesc,
    ) void {
        const cb = cb_obj.body();
        const destination_texture = destination_texture_obj.body();
        const buffer, const region = bufferImageCopy(cb.d, destination_texture, source, size, desc);
        cb.d.handle.cmdCopyBufferToImage2(cb.handle, &.{
            .src_buffer = buffer,
            .dst_image = destination_texture.image,
            .dst_image_layout = .general,
            .region_count = 1,
            .p_regions = &.{region},
        });
    }

    fn bufferImageCopy(
        d: *Device,
        texture: *const Texture,
        address: sc.DeviceAddress,
        size: usize,
        desc: sc.TextureCopyDesc,
    ) struct { vk.Buffer, vk.BufferImageCopy2 } {
        const entry, const offset = d.heap.entryAndOffsetFromAddr(address);
        std.debug.assert(offset + size <= entry.size);

        const texture_extent: [3]u32 = .{ texture.desc.extent.width, texture.desc.extent.height, texture.desc.extent.depth };
        const texel_offset: [3]u32 = .{ @intCast(desc.offset.x), @intCast(desc.offset.y), @intCast(desc.offset.z) };
        var extent: [3]u32 = .{ desc.extent.width, desc.extent.height, desc.extent.depth };
        for (&extent, texel_offset, texture_extent) |*extent_size, start, texture_size| {
            if (extent_size.* == 0) extent_size.* = @max(texture_size >> @intCast(desc.mip), 1) - start;
        }

        const block = to_vk.blockForFormat(texture.desc.format);
        const row_bytes = (extent[0] + block.width - 1) / block.width * block.size;
        const row_pitch_bytes = if (desc.row_pitch_bytes != 0) desc.row_pitch_bytes else row_bytes;
        const layer_count = if (desc.layer_count == 0) texture.desc.layer_count - desc.base_layer else desc.layer_count;

        const block_row_count = (extent[1] + block.height - 1) / block.height;
        const slice_pitch_bytes = if (desc.slice_pitch_bytes != 0) desc.slice_pitch_bytes else block_row_count * row_pitch_bytes;
        std.debug.assert(size >= (extent[2] * layer_count - 1) * slice_pitch_bytes + (block_row_count - 1) * row_pitch_bytes + row_bytes);

        return .{ entry.buffer, .{
            .buffer_offset = offset,
            .buffer_row_length = @intCast(@divExact(desc.row_pitch_bytes, block.size) * block.width),
            .buffer_image_height = @intCast(@divExact(desc.slice_pitch_bytes, row_pitch_bytes) * block.height),
            .image_subresource = .{
                .aspect_mask = to_vk.singleAspectForFormat(texture.desc.format),
                .mip_level = desc.mip,
                .base_array_layer = desc.base_layer,
                .layer_count = layer_count,
            },
            .image_offset = .{ .x = desc.offset.x, .y = desc.offset.y, .z = desc.offset.z },
            .image_extent = .{ .width = extent[0], .height = extent[1], .depth = extent[2] },
        } };
    }

    pub fn copyMemory(
        cb_obj: *Object(CommandBuffer),
        source: sc.DeviceAddress,
        destination: sc.DeviceAddress,
        size: usize,
    ) void {
        const cb = cb_obj.body();
        if (size == 0) return;
        const source_entry, const source_offset = cb.d.heap.entryAndOffsetFromAddr(source);
        const destination_entry, const destination_offset = cb.d.heap.entryAndOffsetFromAddr(destination);
        std.debug.assert(source_offset + size <= source_entry.size);
        std.debug.assert(destination_offset + size <= destination_entry.size);
        cb.d.handle.cmdCopyBuffer2(cb.handle, &.{
            .src_buffer = source_entry.buffer,
            .dst_buffer = destination_entry.buffer,
            .region_count = 1,
            .p_regions = &.{.{ .src_offset = source_offset, .dst_offset = destination_offset, .size = size }},
        });
    }

    pub fn beginRenderPass(cb_obj: *Object(CommandBuffer), desc: sc.RenderPassDesc) void {
        const cb = cb_obj.body();
        const color_targets = if (desc.color_attachments) |color_attachments| color_attachments[0..desc.color_attachment_count] else &.{};
        std.debug.assert(color_targets.len <= 8);

        var color_attachments: [8]vk.RenderingAttachmentInfo = undefined;
        for (color_targets, color_attachments[0..color_targets.len]) |target, *attachment| {
            attachment.* = renderingAttachment(target.texture, target.load_op, target.store_op, .{
                .color = .{ .float_32 = target.clear_color },
            });
        }
        const depth = desc.depth_attachment;
        const depth_attachment = if (depth.texture) |texture| renderingAttachment(texture, depth.load_op, depth.store_op, .{
            .depth_stencil = .{ .depth = depth.clear_value, .stencil = 0 },
        }) else null;
        const stencil = desc.stencil_attachment;
        const stencil_attachment = if (stencil.texture) |texture| renderingAttachment(texture, stencil.load_op, stencil.store_op, .{
            .depth_stencil = .{ .depth = 0, .stencil = stencil.clear_value },
        }) else null;

        const first_texture = if (color_targets.len > 0) color_targets[0].texture else depth.texture orelse stencil.texture.?;
        const first_texture_extent = textureFromHandle(first_texture).desc.extent;
        const extent: vk.Extent2D = .{ .width = first_texture_extent.width, .height = first_texture_extent.height };

        cb.d.handle.cmdBeginRendering(cb.handle, &.{
            .render_area = .{ .offset = .{ .x = 0, .y = 0 }, .extent = extent },
            .layer_count = 1,
            .view_mask = 0,
            .color_attachment_count = @intCast(color_targets.len),
            .p_color_attachments = &color_attachments,
            .p_depth_attachment = if (depth_attachment) |*attachment| attachment else null,
            .p_stencil_attachment = if (stencil_attachment) |*attachment| attachment else null,
        });
        cb.in_render_pass = true;

        cb.d.handle.cmdSetViewport(cb.handle, 0, &.{.{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(extent.width),
            .height = @floatFromInt(extent.height),
            .min_depth = 0,
            .max_depth = 1,
        }});
        cb.d.handle.cmdSetScissor(cb.handle, 0, &.{.{ .offset = .{ .x = 0, .y = 0 }, .extent = extent }});
        cb.d.handle.cmdSetDepthTestEnable(cb.handle, .false);
        cb.d.handle.cmdSetDepthWriteEnable(cb.handle, .false);
        cb.d.handle.cmdSetDepthCompareOp(cb.handle, .always);
        cb.d.handle.cmdSetDepthBiasEnable(cb.handle, .false);
        cb.d.handle.cmdSetStencilTestEnable(cb.handle, .false);
    }
    fn renderingAttachment(
        texture: *sc.Texture,
        load_op: sc.LoadOp,
        store_op: sc.StoreOp,
        clear_value: vk.ClearValue,
    ) vk.RenderingAttachmentInfo {
        return .{
            .image_view = textureFromHandle(texture).default_view,
            .image_layout = .general,
            .resolve_mode = .{},
            .resolve_image_view = .null,
            .resolve_image_layout = .undefined,
            .load_op = to_vk.attachmentLoadOp(load_op),
            .store_op = to_vk.attachmentStoreOp(store_op),
            .clear_value = clear_value,
        };
    }
    fn textureFromHandle(texture: *sc.Texture) *Texture {
        const texture_obj: *Object(Texture) = @ptrCast(@alignCast(texture));
        return texture_obj.body();
    }

    pub fn endRenderPass(cb_obj: *Object(CommandBuffer)) void {
        const cb = cb_obj.body();
        cb.d.handle.cmdEndRendering(cb.handle);
        cb.in_render_pass = false;
    }

    pub fn setScissor(cb_obj: *Object(CommandBuffer), rect: sc.Rect2D) void {
        const cb = cb_obj.body();
        cb.d.handle.cmdSetScissor(cb.handle, 0, &.{.{
            .offset = .{ .x = rect.offset.x, .y = rect.offset.y },
            .extent = .{ .width = rect.extent.width, .height = rect.extent.height },
        }});
    }

    pub fn setViewport(cb_obj: *Object(CommandBuffer), viewport: sc.Viewport) void {
        const cb = cb_obj.body();
        std.debug.assert(cb.in_render_pass);
        cb.d.handle.cmdSetViewport(cb.handle, 0, &.{.{
            .x = viewport.x,
            .y = viewport.y,
            .width = viewport.width,
            .height = viewport.height,
            .min_depth = viewport.min_depth,
            .max_depth = viewport.max_depth,
        }});
    }

    pub fn setDepthBias(cb_obj: *Object(CommandBuffer), depth_bias: sc.DepthBias) void {
        const cb = cb_obj.body();
        if (depth_bias.constant == 0 and depth_bias.slope == 0) {
            cb.d.handle.cmdSetDepthBiasEnable(cb.handle, .false);
            return;
        }
        cb.d.handle.cmdSetDepthBiasEnable(cb.handle, .true);
        cb.d.handle.cmdSetDepthBias(
            cb.handle,
            depth_bias.constant,
            depth_bias.clamp,
            depth_bias.slope,
        );
    }

    pub fn draw(
        cb: *Object(CommandBuffer),
        vertex_data: sc.DeviceAddress,
        pixel_data: sc.DeviceAddress,
        vertex_count: u32,
        instance_count: u32,
    ) void {
        pushRootPointers(cb.body(), vertex_data, pixel_data);
        cb.body().d.handle.cmdDraw(cb.body().handle, vertex_count, instance_count, 0, 0);
    }

    pub fn drawIndexed(
        cb: *Object(CommandBuffer),
        vertex_data: sc.DeviceAddress,
        pixel_data: sc.DeviceAddress,
        index_type: sc.IndexType,
        indices: sc.DeviceAddress,
        index_count: u32,
    ) void {
        drawIndexedInstanced(cb, vertex_data, pixel_data, index_type, indices, index_count, 1);
    }

    pub fn drawIndexedInstanced(
        cb: *Object(CommandBuffer),
        vertex_data: sc.DeviceAddress,
        pixel_data: sc.DeviceAddress,
        index_type: sc.IndexType,
        indices: sc.DeviceAddress,
        index_count: u32,
        instance_count: u32,
    ) void {
        pushRootPointers(cb.body(), vertex_data, pixel_data);
        bindIndexPointer(cb.body(), index_type, indices);
        cb.body().d.handle.cmdDrawIndexed(cb.body().handle, index_count, instance_count, 0, 0, 0);
    }

    pub fn drawIndexedInstancedIndirect(
        cb: *Object(CommandBuffer),
        vertex_data: sc.DeviceAddress,
        pixel_data: sc.DeviceAddress,
        index_type: sc.IndexType,
        indices: sc.DeviceAddress,
        args: sc.DeviceAddress,
        draw_count: u32,
    ) void {
        pushRootPointers(cb.body(), vertex_data, pixel_data);
        bindIndexPointer(cb.body(), index_type, indices);
        const entry, const offset = cb.body().d.heap.entryAndOffsetFromAddr(args);
        cb.body().d.handle.cmdDrawIndexedIndirect(cb.body().handle, entry.buffer, offset, draw_count, @sizeOf(sc.DrawIndexedArguments));
    }

    pub fn drawIndirect(
        cb: *Object(CommandBuffer),
        vertex_data: sc.DeviceAddress,
        pixel_data: sc.DeviceAddress,
        args: sc.DeviceAddress,
        draw_count: u32,
    ) void {
        pushRootPointers(cb.body(), vertex_data, pixel_data);
        const entry, const offset = cb.body().d.heap.entryAndOffsetFromAddr(args);
        cb.body().d.handle.cmdDrawIndirect(cb.body().handle, entry.buffer, offset, draw_count, @sizeOf(sc.DrawArguments));
    }

    fn pushRootPointers(cb: *CommandBuffer, vertex_data: sc.DeviceAddress, pixel_data: sc.DeviceAddress) void {
        const addresses = [2]vk.DeviceAddress{ vertex_data, pixel_data };
        cb.d.handle.cmdPushConstants(cb.handle, cb.pipeline_layout, .{ .vertex = true, .fragment = true }, 0, @sizeOf(@TypeOf(addresses)), &addresses);
    }

    fn bindIndexPointer(cb: *CommandBuffer, index_type: sc.IndexType, indices: sc.DeviceAddress) void {
        const entry, const offset = cb.d.heap.entryAndOffsetFromAddr(indices);
        cb.d.handle.cmdBindIndexBuffer(cb.handle, entry.buffer, offset, to_vk.indexType(index_type));
    }
};

pub const DepthStencilState = struct {
    desc: sc.DepthStencilDesc,
    d: *Device,

    pub fn create(d: *Object(Device), desc: sc.DepthStencilDesc, depth_stencil_state: **Object(DepthStencilState)) !void {
        depth_stencil_state.* = try d.body().depth_stencil_states.create(d.body().gpa);
        depth_stencil_state.*.set(d.body().table, .{ .desc = desc, .d = d.body() });
    }

    pub fn destroy(depth_stencil_state: *Object(DepthStencilState)) void {
        depth_stencil_state.body().d.depth_stencil_states.destroy(depth_stencil_state);
    }
};

pub const Texture = struct {
    image: vk.Image,
    desc: Desc,
    default_view: vk.ImageView,
    views: std.hash_map.AutoHashMapUnmanaged(sc.TextureViewDesc, vk.ImageView),
    d: *Device,

    const Desc = sc.TextureDesc;

    pub const Descriptor = opaque {
        pub fn sizeAndHeapAlign(d: *Object(Device)) sc.SizeAlign {
            const properties = &d.body().descriptor_buffer_properties;
            return .{
                .size = @max(properties.sampled_image_descriptor_size, properties.storage_image_descriptor_size),
                .alignment = properties.descriptor_buffer_offset_alignment,
            };
        }

        pub fn storeDescriptor(d: *Object(Device), descriptor: *const sc.Descriptor, heap_ptr: [*]u8, index: usize) void {
            const size = sizeAndHeapAlign(d).size;
            @memcpy(heap_ptr[size * index ..][0..size], descriptor.data[0..size]);
        }
    };

    pub fn sizeAlign(d: *Object(Device), desc: Desc) sc.SizeAlign {
        const requirements = memoryRequirements(d.body().handle, desc);
        return .{ .size = requirements.size, .alignment = requirements.alignment };
    }

    fn memoryRequirements(device: vk.DeviceProxy, desc: Desc) vk.MemoryRequirements {
        var requirements: vk.MemoryRequirements2 = .{ .memory_requirements = undefined };
        device.getDeviceImageMemoryRequirements(&.{ .p_create_info = &to_vk.imageCreateInfo(desc), .plane_aspect = .{} }, &requirements);
        return requirements.memory_requirements;
    }

    pub fn create(d: *Object(Device), desc: Desc, texture_data: sc.DeviceAddress, texture: **Object(Texture)) !void {
        texture.* = createInner(d.body(), desc, texture_data) catch |err| return switch (err) {
            error.OutOfHostMemory, error.OutOfMemory => error.OutOfMemory,
            error.InvalidOpaqueCaptureAddressKHR, error.Unknown => error.Unknown,
            error.OutOfDeviceMemory, error.CompressionExhaustedEXT => error.OutOfDeviceMemory,
        };
    }
    fn createInner(d: *Device, desc: Desc, texture_data: sc.DeviceAddress) !*Object(Texture) {
        std.debug.assert(desc.format != .none);
        const texture = try d.textures.create(d.gpa);
        errdefer d.textures.destroy(texture);

        const image = try d.handle.createImage(&to_vk.imageCreateInfo(desc), null);
        errdefer d.handle.destroyImage(image, null);
        const entry, const offset = d.heap.entryAndOffsetFromAddr(texture_data);
        try d.handle.bindImageMemory(image, entry.memory, offset);

        const default_view = try createView(d, image, desc, .{}, to_vk.aspectsForFormat(desc.format));
        errdefer d.handle.destroyImageView(default_view, null);
        try d.pending_texture_inits.put(d.gpa, image, desc);

        texture.set(d.table, .{
            .image = image,
            .desc = desc,
            .default_view = default_view,
            .views = .empty,
            .d = d,
        });
        return texture;
    }

    pub fn destroy(texture_obj: *Object(Texture)) void {
        const d = texture_obj.body().d;
        texture_obj.body().deinit(true);
        d.textures.destroy(texture_obj);
    }

    fn deinit(texture: *Texture, owns_image: bool) void {
        const d = texture.d;
        _ = d.pending_texture_inits.swapRemove(texture.image);
        d.handle.destroyImageView(texture.default_view, null);
        var it = texture.views.valueIterator();
        while (it.next()) |view| d.handle.destroyImageView(view.*, null);
        texture.views.deinit(d.gpa);
        if (owns_image) d.handle.destroyImage(texture.image, null);
    }

    pub fn storageDescriptor(texture: *Object(Texture), view_desc: sc.TextureViewDesc, descriptor: *sc.Descriptor) !void {
        descriptor.* = descriptorInner(texture.body(), view_desc, .storage_image) catch |err| return switch (err) {
            error.OutOfHostMemory, error.OutOfMemory => error.OutOfMemory,
            error.InvalidOpaqueCaptureAddressKHR, error.Unknown => error.Unknown,
            error.OutOfDeviceMemory => |e| e,
        };
    }

    pub fn viewDescriptor(texture: *Object(Texture), view_desc: sc.TextureViewDesc, descriptor: *sc.Descriptor) !void {
        descriptor.* = descriptorInner(texture.body(), view_desc, .sampled_image) catch |err| return switch (err) {
            error.OutOfHostMemory, error.OutOfMemory => error.OutOfMemory,
            error.InvalidOpaqueCaptureAddressKHR, error.Unknown => error.Unknown,
            error.OutOfDeviceMemory => |e| e,
        };
    }

    fn descriptorInner(texture: *Texture, view_desc: sc.TextureViewDesc, comptime descriptor_type: vk.DescriptorType) !sc.Descriptor {
        const d = texture.d;
        const aspect_mask = to_vk.singleAspectForFormat(texture.desc.format);
        const is_default_view = std.meta.eql(view_desc, sc.TextureViewDesc{}) and
            aspect_mask.toInt() == to_vk.aspectsForFormat(texture.desc.format).toInt();
        const view = if (is_default_view) texture.default_view else view: {
            const entry = try texture.views.getOrPut(d.gpa, view_desc);
            if (!entry.found_existing) {
                errdefer _ = texture.views.remove(view_desc);
                entry.value_ptr.* = try createView(d, texture.image, texture.desc, view_desc, aspect_mask);
            }
            break :view entry.value_ptr.*;
        };
        const image_info: vk.DescriptorImageInfo = .{ .image_view = view, .image_layout = .general, .sampler = .null };
        const properties = &d.descriptor_buffer_properties;
        var descriptor: sc.Descriptor = .{ .data = @splat(0) };
        switch (descriptor_type) {
            .storage_image => d.handle.getDescriptorEXT(&.{
                .type = .storage_image,
                .data = .{ .p_storage_image = &image_info },
            }, properties.storage_image_descriptor_size, &descriptor.data),
            .sampled_image => d.handle.getDescriptorEXT(&.{
                .type = .sampled_image,
                .data = .{ .p_sampled_image = &image_info },
            }, properties.sampled_image_descriptor_size, &descriptor.data),
            else => comptime unreachable,
        }
        return descriptor;
    }

    fn createView(
        d: *Device,
        image: vk.Image,
        texture_desc: Desc,
        view_desc: sc.TextureViewDesc,
        aspect_mask: vk.ImageAspectFlags,
    ) !vk.ImageView {
        const layer_count = if (view_desc.layer_count == 0) texture_desc.layer_count - view_desc.base_layer else view_desc.layer_count;
        return d.handle.createImageView(&.{
            .image = image,
            .view_type = to_vk.viewType(texture_desc.type, layer_count),
            .format = to_vk.format(if (view_desc.format == .none) texture_desc.format else view_desc.format),
            .subresource_range = .{
                .aspect_mask = aspect_mask,
                .base_mip_level = view_desc.base_mip,
                .level_count = if (view_desc.mip_count == 0) vk.REMAINING_MIP_LEVELS else view_desc.mip_count,
                .base_array_layer = view_desc.base_layer,
                .layer_count = layer_count,
            },
            .components = .{ .r = .identity, .g = .identity, .b = .identity, .a = .identity },
        }, null);
    }
};

pub const Pipeline = struct {
    handle: vk.Pipeline = .null,
    pipeline_layout: vk.PipelineLayout = .null,
    bind_point: vk.PipelineBindPoint,

    samplers: []vk.Sampler = &.{},
    sampler_set_layout: vk.DescriptorSetLayout = .null,

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
            error.InvalidShaderNV, error.MalformedScir => error.MalformedScir,
            error.UnsupportedScirVersion, error.UnsupportedScirBytecode, error.OutOfDeviceMemory => |e| e,
        };
    }
    fn createComputeInner(d: *Device, ir: []const u8) !*Object(Pipeline) {
        const shader = try scir.parse(ir);

        var pipeline: Pipeline = .{ .bind_point = .compute, .d = d };
        errdefer pipeline.deinit();
        try pipeline.createLayout(&.{shader}, .{ .compute = true }, 1);

        const module = try createShaderModule(d, shader);
        defer d.handle.destroyShaderModule(module, null);
        _ = try d.handle.createComputePipelines(.null, &.{.{
            .flags = .{ .descriptor_buffer_ext = true },
            .stage = .{ .stage = .{ .compute = true }, .module = module, .p_name = "main" },
            .layout = pipeline.pipeline_layout,
            .base_pipeline_index = -1,
        }}, null, (&pipeline.handle)[0..1]);

        const pipeline_obj = try d.pipelines.create(d.gpa);
        pipeline_obj.set(d.table, pipeline);
        return pipeline_obj;
    }

    // TODO: rename to createRaster?
    pub fn createGraphics(
        d: *Object(Device),
        vertex_ir_size: usize,
        vertex_ir: [*]const u8,
        pixel_ir_size: usize,
        pixel_ir: [*]const u8,
        desc: sc.GraphicsPipelineDesc,
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
            error.InvalidShaderNV, error.MalformedScir => error.MalformedScir,
            error.UnsupportedScirVersion, error.UnsupportedScirBytecode, error.OutOfDeviceMemory => |e| e,
        };
    }
    fn createGraphicsInner(
        d: *Device,
        vertex_ir: []const u8,
        pixel_ir: []const u8,
        desc: sc.GraphicsPipelineDesc,
    ) !*Object(Pipeline) {
        const color_targets = if (desc.color_targets) |color_targets| color_targets[0..desc.color_target_count] else &.{};
        std.debug.assert(color_targets.len <= 8);
        const shaders = [_]scir.Shader{ try scir.parse(vertex_ir), try scir.parse(pixel_ir) };

        var pipeline: Pipeline = .{ .bind_point = .graphics, .d = d };
        errdefer pipeline.deinit();
        try pipeline.createLayout(&shaders, .{ .vertex = true, .fragment = true }, 2);

        const vertex_module = try createShaderModule(d, shaders[0]);
        defer d.handle.destroyShaderModule(vertex_module, null);
        const pixel_module = try createShaderModule(d, shaders[1]);
        defer d.handle.destroyShaderModule(pixel_module, null);
        const stages = [_]vk.PipelineShaderStageCreateInfo{
            .{ .stage = .{ .vertex = true }, .module = vertex_module, .p_name = "main" },
            .{ .stage = .{ .fragment = true }, .module = pixel_module, .p_name = "main" },
        };

        var color_formats: [8]vk.Format = undefined;
        var blend_attachments: [8]vk.PipelineColorBlendAttachmentState = undefined;
        for (color_targets, color_formats[0..color_targets.len], blend_attachments[0..color_targets.len]) |target, *format, *blend_attachment| {
            std.debug.assert(target.format != .none);
            format.* = to_vk.format(target.format);
            blend_attachment.* = to_vk.colorBlendAttachment(target.blend, target.write_mask);
        }

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
        const rendering_info: vk.PipelineRenderingCreateInfo = .{
            .view_mask = 0,
            .color_attachment_count = @intCast(color_targets.len),
            .p_color_attachment_formats = &color_formats,
            .depth_attachment_format = to_vk.format(desc.depth_format),
            .stencil_attachment_format = to_vk.format(desc.stencil_format),
        };
        const stencil_placeholder = std.mem.zeroInit(vk.StencilOpState, .{});
        _ = try d.handle.createGraphicsPipelines(.null, &.{.{
            .p_next = &rendering_info,
            .flags = .{ .descriptor_buffer_ext = true },
            .stage_count = stages.len,
            .p_stages = &stages,
            .p_vertex_input_state = &.{},
            .p_input_assembly_state = &.{
                .topology = to_vk.topology(desc.topology),
                .primitive_restart_enable = .false,
            },
            .p_viewport_state = &.{ .viewport_count = 1, .scissor_count = 1 },
            .p_rasterization_state = &.{
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
            },
            .p_multisample_state = &.{
                .rasterization_samples = to_vk.sampleCount(@intCast(desc.sample_count)),
                .sample_shading_enable = .false,
                .min_sample_shading = 0,
                .alpha_to_coverage_enable = .fromBool(desc.alpha_to_coverage),
                .alpha_to_one_enable = .false,
            },
            .p_depth_stencil_state = &.{
                .depth_test_enable = .false,
                .depth_write_enable = .false,
                .depth_compare_op = .always,
                .depth_bounds_test_enable = .false,
                .stencil_test_enable = .false,
                .front = stencil_placeholder,
                .back = stencil_placeholder,
                .min_depth_bounds = 0,
                .max_depth_bounds = 1,
            },
            .p_color_blend_state = &.{
                .logic_op_enable = .false,
                .logic_op = .copy,
                .attachment_count = @intCast(color_targets.len),
                .p_attachments = &blend_attachments,
                .blend_constants = .{ 0, 0, 0, 0 },
            },
            .p_dynamic_state = &.{ .dynamic_state_count = dynamic_states.len, .p_dynamic_states = &dynamic_states },
            .layout = pipeline.pipeline_layout,
            .render_pass = .null,
            .subpass = 0,
            .base_pipeline_index = -1,
        }}, null, (&pipeline.handle)[0..1]);

        const pipeline_obj = try d.pipelines.create(d.gpa);
        pipeline_obj.set(d.table, pipeline);
        return pipeline_obj;
    }

    pub fn destroy(pipeline_obj: *Object(Pipeline)) void {
        const d = pipeline_obj.body().d;
        pipeline_obj.body().deinit();
        d.pipelines.destroy(pipeline_obj);
    }

    fn deinit(pipeline: Pipeline) void {
        const device = pipeline.d.handle;
        device.destroyPipeline(pipeline.handle, null);
        device.destroyPipelineLayout(pipeline.pipeline_layout, null);
        device.destroyDescriptorSetLayout(pipeline.sampler_set_layout, null);
        for (pipeline.samplers) |sampler| device.destroySampler(sampler, null);
        pipeline.d.gpa.free(pipeline.samplers);
    }

    /// set 0 => texture heap
    /// set 1 => immutable samplers
    /// push constants => root addresses.
    fn createLayout(pipeline: *Pipeline, shaders: []const scir.Shader, root_stages: vk.ShaderStageFlags, root_address_count: u32) !void {
        const d = pipeline.d;
        var sampler_count: usize = 0;
        for (shaders) |shader| sampler_count += shader.samplerCount();
        pipeline.samplers = try d.gpa.alloc(vk.Sampler, sampler_count);
        @memset(pipeline.samplers, .null);

        var bindings: [2]vk.DescriptorSetLayoutBinding = undefined;
        std.debug.assert(shaders.len <= bindings.len);
        var binding_count: u32 = 0;
        var stage_samplers_start: usize = 0;
        for (shaders, 0..) |shader, stage_index| {
            const stage_samplers = pipeline.samplers[stage_samplers_start..][0..shader.samplerCount()];
            stage_samplers_start += stage_samplers.len;
            for (stage_samplers, 0..) |*sampler, i| {
                const sampler_desc = shader.sampler(i);
                const reduction_info: vk.SamplerReductionModeCreateInfo = .{
                    .reduction_mode = to_vk.samplerReductionMode(sampler_desc.reduction),
                };
                var create_info = to_vk.samplerCreateInfo(sampler_desc);
                create_info.p_next = &reduction_info;
                sampler.* = try d.handle.createSampler(&create_info, null);
            }
            if (stage_samplers.len == 0) continue;
            bindings[binding_count] = .{
                .binding = @intCast(stage_index),
                .descriptor_type = .sampler,
                .descriptor_count = @intCast(stage_samplers.len),
                .stage_flags = .{ .vertex = true, .fragment = true, .compute = true },
                .p_immutable_samplers = stage_samplers.ptr,
            };
            binding_count += 1;
        }
        pipeline.sampler_set_layout = try d.handle.createDescriptorSetLayout(&.{
            .flags = .{ .descriptor_buffer_ext = true, .embedded_immutable_samplers_ext = true },
            .binding_count = binding_count,
            .p_bindings = &bindings,
        }, null);

        pipeline.pipeline_layout = try d.handle.createPipelineLayout(&.{
            .set_layout_count = 2,
            .p_set_layouts = &.{ d.texture_heap_set_layout, pipeline.sampler_set_layout },
            .push_constant_range_count = 1,
            .p_push_constant_ranges = &.{.{
                .stage_flags = root_stages,
                .offset = 0,
                .size = root_address_count * @sizeOf(vk.DeviceAddress),
            }},
        }, null);
    }

    fn createShaderModule(d: *Device, shader: scir.Shader) !vk.ShaderModule {
        const spirv = try shader.spirvAlloc(d.gpa);
        defer d.gpa.free(spirv);
        return d.handle.createShaderModule(&.{ .code_size = spirv.len * @sizeOf(u32), .p_code = spirv.ptr }, null);
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

const wrap_sc_allocator = struct {
    fn alloc(user_data: *anyopaque, len: usize, alignment: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
        _ = ret_addr;
        const sc_gpa: *sc.HostAllocator = @ptrCast(@alignCast(user_data));
        return sc_gpa.alloc(sc_gpa.user_data, len, alignment.toByteUnits());
    }
    fn remap(user_data: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
        _ = ret_addr;
        const sc_gpa: *sc.HostAllocator = @ptrCast(@alignCast(user_data));
        return sc_gpa.remap(sc_gpa.user_data, memory.ptr, memory.len, alignment.toByteUnits(), new_len);
    }
    fn free(user_data: *anyopaque, memory: []u8, alignment: std.mem.Alignment, ret_addr: usize) void {
        _ = ret_addr;
        const sc_gpa: *sc.HostAllocator = @ptrCast(@alignCast(user_data));
        return sc_gpa.free(sc_gpa.user_data, memory.ptr, memory.len, alignment.toByteUnits());
    }

    const vtable: *const std.mem.Allocator.VTable = &.{
        .alloc = wrap_sc_allocator.alloc,
        .remap = wrap_sc_allocator.remap,
        .free = wrap_sc_allocator.free,
        .resize = std.mem.Allocator.noResize,
    };
};

pub export fn symbol(name: [*:0]const u8) callconv(sc.@"callconv") *const anyopaque {
    const map = symbol_map.map(.{
        .Instance = Object(Instance),
        .Adapter = Adapter,
        .Surface = Object(Surface),
        .Device = Object(Device),
        .Queue = Object(Queue),
        .Timeline = Object(Timeline),
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
        .surfaceSupportedUsage = Surface.supportedUsage,
        .surfaceSupportedFormats = Surface.supportedFormats,
        .surfacePresentModes = Surface.presentModes,
        .hostFromDevicePointer = Device.hostFromDevicePointer,
        .alloc = Device.alloc,
        .free = Device.free,
        .descriptorSizeAndHeapAlign = Texture.Descriptor.sizeAndHeapAlign,
        .storeDescriptor = Texture.Descriptor.storeDescriptor,
        .getQueue = Queue.getQueue,
        .startCommandRecording = Queue.startCommandRecording,
        .submit = Queue.submit,
        .submitAndSignal = Queue.submitAndSignal,
        .createTimeline = Timeline.create,
        .destroyTimeline = Timeline.destroy,
        .waitTimelinePoint = Timeline.wait,
        .createSwapchain = Swapchain.create,
        .destroySwapchain = Swapchain.destroy,
        .acquireBackBuffer = Swapchain.acquire,
        .present = Swapchain.present,
        .setActiveTextureHeap = CommandBuffer.setActiveTextureHeap,
        .setPipeline = CommandBuffer.setPipeline,
        .setDepthStencilState = CommandBuffer.setDepthStencilState,
        .dispatch = CommandBuffer.dispatch,
        .dispatchIndirect = CommandBuffer.dispatchIndirect,
        .barrier = CommandBuffer.barrier,
        .copyTextureToMemory = CommandBuffer.copyTextureToMemory,
        .copyMemoryToTexture = CommandBuffer.copyMemoryToTexture,
        .copyMemory = CommandBuffer.copyMemory,
        .beginRenderPass = CommandBuffer.beginRenderPass,
        .endRenderPass = CommandBuffer.endRenderPass,
        .setScissor = CommandBuffer.setScissor,
        .setViewport = CommandBuffer.setViewport,
        .draw = CommandBuffer.draw,
        .drawIndexed = CommandBuffer.drawIndexed,
        .drawIndexedInstanced = CommandBuffer.drawIndexedInstanced,
        .drawIndexedInstancedIndirect = CommandBuffer.drawIndexedInstancedIndirect,
        .drawIndirect = CommandBuffer.drawIndirect,
        .textureSizeAlign = Texture.sizeAlign,
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

fn debugCallback(
    message_severity: vk.DebugUtilsMessageSeverityFlagsEXT,
    message_types: vk.DebugUtilsMessageTypeFlagsEXT,
    p_callback_data: ?*const vk.DebugUtilsMessengerCallbackDataEXT,
    p_user_data: ?*anyopaque,
) callconv(vk.vulkan_call_conv) vk.Bool32 {
    _ = .{ message_types, p_user_data };
    const message = if (p_callback_data) |callback_data| std.mem.span(callback_data.p_message orelse "no message") else "no message";
    if (message_severity.error_ext) {
        std.log.err("Validation: {s}", .{message});
    } else {
        std.log.warn("Validation: {s}", .{message});
    }
    std.debug.dumpCurrentStackTrace(.{});
    return .false;
}

fn writeEnumeration(T: type, items: []const T, buffer_capacity: usize, buffer: ?[*]T, count: *usize) void {
    count.* = items.len;
    const buffer_items = buffer orelse return;
    const written_count = @min(buffer_capacity, items.len);
    @memcpy(buffer_items[0..written_count], items[0..written_count]);
}

fn semaphoreSubmitInfo(semaphore: vk.Semaphore, value: u64) vk.SemaphoreSubmitInfo {
    return .{ .semaphore = semaphore, .value = value, .stage_mask = .{ .all_commands = true }, .device_index = 0 };
}

fn layoutTransition(image: vk.Image, desc: sc.TextureDesc, old_layout: vk.ImageLayout, new_layout: vk.ImageLayout) vk.ImageMemoryBarrier2 {
    return .{
        .src_stage_mask = .{ .all_commands = true },
        .src_access_mask = .{ .memory_write = true },
        .dst_stage_mask = .{ .all_commands = true },
        .dst_access_mask = .{ .memory_read = true, .memory_write = true },
        .old_layout = old_layout,
        .new_layout = new_layout,
        .src_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
        .dst_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
        .image = image,
        .subresource_range = .{
            .aspect_mask = to_vk.aspectsForFormat(desc.format),
            .base_mip_level = 0,
            .level_count = desc.mip_count,
            .base_array_layer = 0,
            .layer_count = desc.layer_count,
        },
    };
}
