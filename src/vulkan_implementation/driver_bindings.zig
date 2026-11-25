// Generated file, do not edit.
// version: 0.1.0

const std = @import("std");
const target = @import("builtin").target;

/// `handles` holds the driver's type for each handle.
pub fn Bindings(comptime handles: type) type {
    return struct {
        pub const @"callconv": std.lang.CallingConvention = switch (target.os.tag) {
            .windows => if (target.cpu.arch == .x86) .{ .x86_stdcall = .{} } else .c,
            else => .c,
        };

        pub const descriptor_size_max: usize = 64;
        pub const color_target_count_max: usize = 8;
        pub const adapter_name_capacity_bytes: usize = 256;

        pub const DeviceAddress = u64;

        pub const Instance: type = handles.Instance;
        pub const Surface: type = handles.Surface;
        pub const Adapter: type = handles.Adapter;
        pub const Device: type = handles.Device;
        pub const Queue: type = handles.Queue;
        pub const Timeline: type = handles.Timeline;
        pub const Swapchain: type = handles.Swapchain;
        pub const CommandPool: type = handles.CommandPool;
        pub const CommandBuffer: type = handles.CommandBuffer;
        pub const Texture: type = handles.Texture;
        pub const Pipeline: type = handles.Pipeline;
        pub const DepthStencilState: type = handles.DepthStencilState;
        pub const BlendState: type = handles.BlendState;

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

        /// Graphics stages run in the order indirect, geometry, fragment, color_output, with depth_stencil_tests both before and after fragment.
        /// As `before`, a graphics stage also covers all earlier ones; as `after`, all later ones.
        pub const Stage = packed struct(u32) {
            /// Indirect argument and index fetch, of draws and dispatches.
            indirect: bool = false,
            /// Vertex shading.
            geometry: bool = false,
            fragment: bool = false,
            /// Depth and stencil attachment reads and writes.
            depth_stencil_tests: bool = false,
            /// Color attachment reads and writes.
            color_output: bool = false,
            compute: bool = false,
            transfer: bool = false,
            /// Only valid as `after`: makes writes visible to the host.
            host: bool = false,
            all_commands: bool = false,
            padding: u23 = 0,
        };

        pub const Hazard = packed struct(u32) {
            /// Descriptors written by the GPU before the barrier are read after it.
            descriptors: bool = false,
            padding: u31 = 0,
        };

        pub const TextureUsage = packed struct(u32) {
            sampled: bool = false,
            storage: bool = false,
            color_attachment: bool = false,
            depth_stencil_attachment: bool = false,
            padding: u28 = 0,
        };

        pub const AdapterFeatures = packed struct(u32) {
            /// ScBlendState is available and pipelines may omit their embedded blend state.
            blend_state: bool = false,
            /// scBarrier may be called inside a render pass.
            render_pass_barrier: bool = false,
            padding: u30 = 0,
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

        pub const SizeAlign = extern struct {
            size: usize,
            alignment: usize,
        };

        pub const AdapterInfo = extern struct {
            /// UTF-8, null-terminated.
            name: [adapter_name_capacity_bytes]u8,
            kind: AdapterKind,
            features: AdapterFeatures,
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
            /// Must be supported by the surface for this color space.
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
            /// Listing formats can disable lossless compression.
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

        pub const BlendComponent = extern struct {
            op: BlendOp = .add,
            src_factor: BlendFactor = .one,
            dst_factor: BlendFactor = .zero,
        };

        pub const BlendTarget = extern struct {
            color: BlendComponent = .{},
            alpha: BlendComponent = .{},
            write_mask: ColorWriteMask = .all,
        };

        pub const BlendDesc = extern struct {
            /// Indexed by color attachment.
            targets: [color_target_count_max]BlendTarget = .{ .{}, .{}, .{}, .{}, .{}, .{}, .{}, .{} },
        };

        pub const ColorTarget = extern struct {
            format: Format,
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
            /// SC_FORMAT_NONE for no depth/stencil attachment.
            depth_stencil_format: Format = .none,
            color_targets: ColorTargets = .{},
            /// Embedded blend state, required without SC_ADAPTER_FEATURES_BLEND_STATE_BIT. NULL to set it dynamically with scSetBlendState.
            blend: ?*const BlendDesc = null,
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

        pub const Functions = struct {
            adapterInfo: fn (
                instance: *Instance,
                adapter: *Adapter,
            ) AdapterInfo,
            createSurfaceWin32: fn (
                device: *Device,
                desc: SurfaceWin32Desc,
            ) *Surface,
            createSurfaceXlib: fn (
                device: *Device,
                desc: SurfaceXlibDesc,
            ) *Surface,
            destroySurface: fn (
                surface: *Surface,
            ) void,
            surfaceSupportedUsage: fn (
                surface: *Surface,
            ) TextureUsage,
            surfaceSupportedFormats: fn (
                surface: *Surface,
                color_space: ColorSpace,
                formats_capacity: usize,
                formats: ?[*]Format,
                format_count: *usize,
            ) void,
            surfacePresentModes: fn (
                surface: *Surface,
                present_modes_capacity: usize,
                present_modes: ?[*]PresentMode,
                present_mode_count: *usize,
            ) void,
            hostFromDevicePointer: fn (
                device: *Device,
                address: DeviceAddress,
            ) *anyopaque,
            alloc: fn (
                device: *Device,
                size: usize,
                alignment: usize,
                memory: MemoryKind,
                device_mapping: *HostDeviceAddress,
            ) error{
                OutOfMemory,
                OutOfDeviceMemory,
            }!void,
            free: fn (
                device: *Device,
                address: DeviceAddress,
            ) void,
            descriptorSizeAndHeapAlign: fn (
                device: *Device,
            ) SizeAlign,
            getQueue: fn (
                device: *Device,
                queue_kind: QueueKind,
            ) *Queue,
            textureCopyGranularity: fn (
                queue: *Queue,
            ) Extent3D,
            createCommandPool: fn (
                queue: *Queue,
                command_pool: **CommandPool,
            ) error{
                OutOfMemory,
                OutOfDeviceMemory,
                Unknown,
            }!void,
            destroyCommandPool: fn (
                command_pool: *CommandPool,
            ) void,
            resetCommandPool: fn (
                command_pool: *CommandPool,
            ) error{
                OutOfDeviceMemory,
                Unknown,
            }!void,
            startCommandRecording: fn (
                command_pool: *CommandPool,
                command_buffer: **CommandBuffer,
            ) error{
                OutOfMemory,
                OutOfDeviceMemory,
                Unknown,
            }!void,
            submit: fn (
                queue: *Queue,
                command_buffer_count: usize,
                command_buffers: [*]const *CommandBuffer,
                wait_count: usize,
                waits: [*]const TimelinePoint,
            ) error{
                OutOfDeviceMemory,
                OutOfMemory,
                DeviceLost,
                Unknown,
            }!void,
            submitAndSignal: fn (
                queue: *Queue,
                command_buffer_count: usize,
                command_buffers: [*]const *CommandBuffer,
                wait_count: usize,
                waits: [*]const TimelinePoint,
                signal: TimelinePoint,
            ) error{
                OutOfDeviceMemory,
                OutOfMemory,
                DeviceLost,
                Unknown,
            }!void,
            createTimeline: fn (
                device: *Device,
                initial_value: u64,
                timeline: **Timeline,
            ) error{
                OutOfMemory,
                OutOfDeviceMemory,
                Unknown,
            }!void,
            destroyTimeline: fn (
                timeline: *Timeline,
            ) void,
            waitTimelinePoint: fn (
                point: TimelinePoint,
            ) error{
                OutOfDeviceMemory,
                OutOfMemory,
                DeviceLost,
                Unknown,
            }!void,
            createSwapchain: fn (
                queue: *Queue,
                surface: *Surface,
                desc: SwapchainDesc,
                swapchain: **Swapchain,
            ) error{
                OutOfDeviceMemory,
                OutOfMemory,
                SurfaceLost,
                Unknown,
            }!void,
            destroySwapchain: fn (
                swapchain: *Swapchain,
            ) void,
            acquireBackBuffer: fn (
                swapchain: *Swapchain,
                extent: Extent2D,
                back_buffer: *BackBuffer,
            ) error{
                OutOfMemory,
                OutOfDeviceMemory,
                DeviceLost,
                SurfaceLost,
                NoBackbuffer,
                Unknown,
            }!void,
            present: fn (
                swapchain: *Swapchain,
            ) error{
                OutOfMemory,
                OutOfDeviceMemory,
                DeviceLost,
                SurfaceLost,
                Unknown,
            }!void,
            setActiveTextureHeap: fn (
                command_buffer: *CommandBuffer,
                heap_address: DeviceAddress,
            ) void,
            setDepthStencilState: fn (
                command_buffer: *CommandBuffer,
                depth_stencil_state: *DepthStencilState,
            ) void,
            setBlendState: fn (
                command_buffer: *CommandBuffer,
                blend_state: *BlendState,
            ) void,
            setPipeline: fn (
                command_buffer: *CommandBuffer,
                pipeline: *Pipeline,
            ) void,
            dispatch: fn (
                command_buffer: *CommandBuffer,
                data: DeviceAddress,
                x: u32,
                y: u32,
                z: u32,
            ) void,
            dispatchIndirect: fn (
                command_buffer: *CommandBuffer,
                data: DeviceAddress,
                arguments: DeviceAddress,
            ) void,
            barrier: fn (
                command_buffer: *CommandBuffer,
                before: Stage,
                after: Stage,
                hazard: Hazard,
            ) void,
            copyTextureToMemory: fn (
                command_buffer: *CommandBuffer,
                source_texture: *Texture,
                destination: DeviceAddress,
                size: usize,
                desc: TextureCopyDesc,
            ) void,
            copyMemoryToTexture: fn (
                command_buffer: *CommandBuffer,
                source: DeviceAddress,
                size: usize,
                destination_texture: *Texture,
                desc: TextureCopyDesc,
            ) void,
            copyMemory: fn (
                command_buffer: *CommandBuffer,
                source: DeviceAddress,
                destination: DeviceAddress,
                size: usize,
            ) void,
            beginRenderPass: fn (
                command_buffer: *CommandBuffer,
                desc: RenderPassDesc,
            ) void,
            endRenderPass: fn (
                command_buffer: *CommandBuffer,
            ) void,
            setScissor: fn (
                command_buffer: *CommandBuffer,
                rect: Rect2D,
            ) void,
            setViewport: fn (
                command_buffer: *CommandBuffer,
                viewport: Viewport,
            ) void,
            draw: fn (
                command_buffer: *CommandBuffer,
                vertex_data: DeviceAddress,
                pixel_data: DeviceAddress,
                vertex_count: u32,
                instance_count: u32,
            ) void,
            drawIndexed: fn (
                command_buffer: *CommandBuffer,
                vertex_data: DeviceAddress,
                pixel_data: DeviceAddress,
                index_type: IndexType,
                indices: DeviceAddress,
                index_count: u32,
            ) void,
            drawIndexedInstanced: fn (
                command_buffer: *CommandBuffer,
                vertex_data: DeviceAddress,
                pixel_data: DeviceAddress,
                index_type: IndexType,
                indices: DeviceAddress,
                index_count: u32,
                instance_count: u32,
            ) void,
            drawIndexedInstancedIndirect: fn (
                command_buffer: *CommandBuffer,
                vertex_data: DeviceAddress,
                pixel_data: DeviceAddress,
                index_type: IndexType,
                indices: DeviceAddress,
                arguments: DeviceAddress,
                draw_count: u32,
            ) void,
            drawIndirect: fn (
                command_buffer: *CommandBuffer,
                vertex_data: DeviceAddress,
                pixel_data: DeviceAddress,
                arguments: DeviceAddress,
                draw_count: u32,
            ) void,
            textureSizeAlign: fn (
                device: *Device,
                desc: TextureDesc,
            ) SizeAlign,
            textureSampleCountMax: fn (
                device: *Device,
                desc: TextureDesc,
            ) u32,
            createTexture: fn (
                device: *Device,
                desc: TextureDesc,
                memory: DeviceAddress,
                texture: **Texture,
            ) error{
                OutOfMemory,
                OutOfDeviceMemory,
                Unknown,
            }!void,
            destroyTexture: fn (
                texture: *Texture,
            ) void,
            textureStorageDescriptor: fn (
                texture: *Texture,
                desc: TextureViewDesc,
                descriptor: *Descriptor,
            ) error{
                OutOfMemory,
                OutOfDeviceMemory,
                Unknown,
            }!void,
            textureViewDescriptor: fn (
                texture: *Texture,
                desc: TextureViewDesc,
                descriptor: *Descriptor,
            ) error{
                OutOfMemory,
                OutOfDeviceMemory,
                Unknown,
            }!void,
            createComputePipeline: fn (
                device: *Device,
                ir_size: usize,
                ir: [*]const u8,
                pipeline: **Pipeline,
            ) error{
                OutOfMemory,
                OutOfDeviceMemory,
                MalformedScir,
                UnsupportedScirVersion,
                UnsupportedScirBytecode,
                Unknown,
            }!void,
            createGraphicsPipeline: fn (
                device: *Device,
                vertex_ir_size: usize,
                vertex_ir: [*]const u8,
                pixel_ir_size: usize,
                pixel_ir: [*]const u8,
                desc: GraphicsPipelineDesc,
                pipeline: **Pipeline,
            ) error{
                OutOfMemory,
                OutOfDeviceMemory,
                MalformedScir,
                UnsupportedScirVersion,
                UnsupportedScirBytecode,
                Unknown,
            }!void,
            destroyPipeline: fn (
                pipeline: *Pipeline,
            ) void,
            createBlendState: fn (
                device: *Device,
                desc: BlendDesc,
                blend_state: **BlendState,
            ) error{
                OutOfMemory,
            }!void,
            destroyBlendState: fn (
                blend_state: *BlendState,
            ) void,
            createDepthStencilState: fn (
                device: *Device,
                desc: DepthStencilDesc,
                depth_stencil_state: **DepthStencilState,
            ) error{
                OutOfMemory,
            }!void,
            destroyDepthStencilState: fn (
                depth_stencil_state: *DepthStencilState,
            ) void,
        };

        fn CFunctions(comptime functions: Functions) type {
            return struct {
                const Error = error{
                    Unknown,
                    OutOfMemory,
                    OutOfDeviceMemory,
                    DeviceLost,
                    SurfaceLost,
                    NoBackbuffer,
                    MalformedScir,
                    UnsupportedScirVersion,
                    UnsupportedScirBytecode,
                };

                fn cResult(result: anytype) Result {
                    if (result) return .ok else |err| return switch (@as(Error, err)) {
                        error.Unknown => .unknown,
                        error.OutOfMemory => .out_of_memory,
                        error.OutOfDeviceMemory => .out_of_device_memory,
                        error.DeviceLost => .device_lost,
                        error.SurfaceLost => .surface_lost,
                        error.NoBackbuffer => .no_backbuffer,
                        error.MalformedScir => .malformed_scir,
                        error.UnsupportedScirVersion => .unsupported_scir_version,
                        error.UnsupportedScirBytecode => .unsupported_scir_bytecode,
                    };
                }

                pub fn adapterInfo(
                    instance: *Instance,
                    adapter: *Adapter,
                ) callconv(@"callconv") AdapterInfo {
                    return functions.adapterInfo(
                        instance,
                        adapter,
                    );
                }

                pub fn createSurfaceWin32(
                    device: *Device,
                    desc: SurfaceWin32Desc,
                ) callconv(@"callconv") *Surface {
                    return functions.createSurfaceWin32(
                        device,
                        desc,
                    );
                }

                pub fn createSurfaceXlib(
                    device: *Device,
                    desc: SurfaceXlibDesc,
                ) callconv(@"callconv") *Surface {
                    return functions.createSurfaceXlib(
                        device,
                        desc,
                    );
                }

                pub fn destroySurface(
                    surface: *Surface,
                ) callconv(@"callconv") void {
                    return functions.destroySurface(
                        surface,
                    );
                }

                pub fn surfaceSupportedUsage(
                    surface: *Surface,
                ) callconv(@"callconv") TextureUsage {
                    return functions.surfaceSupportedUsage(
                        surface,
                    );
                }

                pub fn surfaceSupportedFormats(
                    surface: *Surface,
                    color_space: ColorSpace,
                    formats_capacity: usize,
                    formats: ?[*]Format,
                    format_count: *usize,
                ) callconv(@"callconv") void {
                    return functions.surfaceSupportedFormats(
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
                ) callconv(@"callconv") void {
                    return functions.surfacePresentModes(
                        surface,
                        present_modes_capacity,
                        present_modes,
                        present_mode_count,
                    );
                }

                pub fn hostFromDevicePointer(
                    device: *Device,
                    address: DeviceAddress,
                ) callconv(@"callconv") *anyopaque {
                    return functions.hostFromDevicePointer(
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
                ) callconv(@"callconv") Result {
                    return cResult(functions.alloc(
                        device,
                        size,
                        alignment,
                        memory,
                        device_mapping,
                    ));
                }

                pub fn free(
                    device: *Device,
                    address: DeviceAddress,
                ) callconv(@"callconv") void {
                    return functions.free(
                        device,
                        address,
                    );
                }

                pub fn descriptorSizeAndHeapAlign(
                    device: *Device,
                ) callconv(@"callconv") SizeAlign {
                    return functions.descriptorSizeAndHeapAlign(
                        device,
                    );
                }

                pub fn getQueue(
                    device: *Device,
                    queue_kind: QueueKind,
                ) callconv(@"callconv") *Queue {
                    return functions.getQueue(
                        device,
                        queue_kind,
                    );
                }

                pub fn textureCopyGranularity(
                    queue: *Queue,
                ) callconv(@"callconv") Extent3D {
                    return functions.textureCopyGranularity(
                        queue,
                    );
                }

                pub fn createCommandPool(
                    queue: *Queue,
                    command_pool: **CommandPool,
                ) callconv(@"callconv") Result {
                    return cResult(functions.createCommandPool(
                        queue,
                        command_pool,
                    ));
                }

                pub fn destroyCommandPool(
                    command_pool: *CommandPool,
                ) callconv(@"callconv") void {
                    return functions.destroyCommandPool(
                        command_pool,
                    );
                }

                pub fn resetCommandPool(
                    command_pool: *CommandPool,
                ) callconv(@"callconv") Result {
                    return cResult(functions.resetCommandPool(
                        command_pool,
                    ));
                }

                pub fn startCommandRecording(
                    command_pool: *CommandPool,
                    command_buffer: **CommandBuffer,
                ) callconv(@"callconv") Result {
                    return cResult(functions.startCommandRecording(
                        command_pool,
                        command_buffer,
                    ));
                }

                pub fn submit(
                    queue: *Queue,
                    command_buffer_count: usize,
                    command_buffers: [*]const *CommandBuffer,
                    wait_count: usize,
                    waits: [*]const TimelinePoint,
                ) callconv(@"callconv") Result {
                    return cResult(functions.submit(
                        queue,
                        command_buffer_count,
                        command_buffers,
                        wait_count,
                        waits,
                    ));
                }

                pub fn submitAndSignal(
                    queue: *Queue,
                    command_buffer_count: usize,
                    command_buffers: [*]const *CommandBuffer,
                    wait_count: usize,
                    waits: [*]const TimelinePoint,
                    signal: TimelinePoint,
                ) callconv(@"callconv") Result {
                    return cResult(functions.submitAndSignal(
                        queue,
                        command_buffer_count,
                        command_buffers,
                        wait_count,
                        waits,
                        signal,
                    ));
                }

                pub fn createTimeline(
                    device: *Device,
                    initial_value: u64,
                    timeline: **Timeline,
                ) callconv(@"callconv") Result {
                    return cResult(functions.createTimeline(
                        device,
                        initial_value,
                        timeline,
                    ));
                }

                pub fn destroyTimeline(
                    timeline: *Timeline,
                ) callconv(@"callconv") void {
                    return functions.destroyTimeline(
                        timeline,
                    );
                }

                pub fn waitTimelinePoint(
                    point: TimelinePoint,
                ) callconv(@"callconv") Result {
                    return cResult(functions.waitTimelinePoint(
                        point,
                    ));
                }

                pub fn createSwapchain(
                    queue: *Queue,
                    surface: *Surface,
                    desc: SwapchainDesc,
                    swapchain: **Swapchain,
                ) callconv(@"callconv") Result {
                    return cResult(functions.createSwapchain(
                        queue,
                        surface,
                        desc,
                        swapchain,
                    ));
                }

                pub fn destroySwapchain(
                    swapchain: *Swapchain,
                ) callconv(@"callconv") void {
                    return functions.destroySwapchain(
                        swapchain,
                    );
                }

                pub fn acquireBackBuffer(
                    swapchain: *Swapchain,
                    extent: Extent2D,
                    back_buffer: *BackBuffer,
                ) callconv(@"callconv") Result {
                    return cResult(functions.acquireBackBuffer(
                        swapchain,
                        extent,
                        back_buffer,
                    ));
                }

                pub fn present(
                    swapchain: *Swapchain,
                ) callconv(@"callconv") Result {
                    return cResult(functions.present(
                        swapchain,
                    ));
                }

                pub fn setActiveTextureHeap(
                    command_buffer: *CommandBuffer,
                    heap_address: DeviceAddress,
                ) callconv(@"callconv") void {
                    return functions.setActiveTextureHeap(
                        command_buffer,
                        heap_address,
                    );
                }

                pub fn setDepthStencilState(
                    command_buffer: *CommandBuffer,
                    depth_stencil_state: *DepthStencilState,
                ) callconv(@"callconv") void {
                    return functions.setDepthStencilState(
                        command_buffer,
                        depth_stencil_state,
                    );
                }

                pub fn setBlendState(
                    command_buffer: *CommandBuffer,
                    blend_state: *BlendState,
                ) callconv(@"callconv") void {
                    return functions.setBlendState(
                        command_buffer,
                        blend_state,
                    );
                }

                pub fn setPipeline(
                    command_buffer: *CommandBuffer,
                    pipeline: *Pipeline,
                ) callconv(@"callconv") void {
                    return functions.setPipeline(
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
                ) callconv(@"callconv") void {
                    return functions.dispatch(
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
                ) callconv(@"callconv") void {
                    return functions.dispatchIndirect(
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
                ) callconv(@"callconv") void {
                    return functions.barrier(
                        command_buffer,
                        before,
                        after,
                        hazard,
                    );
                }

                pub fn copyTextureToMemory(
                    command_buffer: *CommandBuffer,
                    source_texture: *Texture,
                    destination: DeviceAddress,
                    size: usize,
                    desc: TextureCopyDesc,
                ) callconv(@"callconv") void {
                    return functions.copyTextureToMemory(
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
                ) callconv(@"callconv") void {
                    return functions.copyMemoryToTexture(
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
                ) callconv(@"callconv") void {
                    return functions.copyMemory(
                        command_buffer,
                        source,
                        destination,
                        size,
                    );
                }

                pub fn beginRenderPass(
                    command_buffer: *CommandBuffer,
                    desc: RenderPassDesc,
                ) callconv(@"callconv") void {
                    return functions.beginRenderPass(
                        command_buffer,
                        desc,
                    );
                }

                pub fn endRenderPass(
                    command_buffer: *CommandBuffer,
                ) callconv(@"callconv") void {
                    return functions.endRenderPass(
                        command_buffer,
                    );
                }

                pub fn setScissor(
                    command_buffer: *CommandBuffer,
                    rect: Rect2D,
                ) callconv(@"callconv") void {
                    return functions.setScissor(
                        command_buffer,
                        rect,
                    );
                }

                pub fn setViewport(
                    command_buffer: *CommandBuffer,
                    viewport: Viewport,
                ) callconv(@"callconv") void {
                    return functions.setViewport(
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
                ) callconv(@"callconv") void {
                    return functions.draw(
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
                ) callconv(@"callconv") void {
                    return functions.drawIndexed(
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
                ) callconv(@"callconv") void {
                    return functions.drawIndexedInstanced(
                        command_buffer,
                        vertex_data,
                        pixel_data,
                        index_type,
                        indices,
                        index_count,
                        instance_count,
                    );
                }

                pub fn drawIndexedInstancedIndirect(
                    command_buffer: *CommandBuffer,
                    vertex_data: DeviceAddress,
                    pixel_data: DeviceAddress,
                    index_type: IndexType,
                    indices: DeviceAddress,
                    arguments: DeviceAddress,
                    draw_count: u32,
                ) callconv(@"callconv") void {
                    return functions.drawIndexedInstancedIndirect(
                        command_buffer,
                        vertex_data,
                        pixel_data,
                        index_type,
                        indices,
                        arguments,
                        draw_count,
                    );
                }

                pub fn drawIndirect(
                    command_buffer: *CommandBuffer,
                    vertex_data: DeviceAddress,
                    pixel_data: DeviceAddress,
                    arguments: DeviceAddress,
                    draw_count: u32,
                ) callconv(@"callconv") void {
                    return functions.drawIndirect(
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
                ) callconv(@"callconv") SizeAlign {
                    return functions.textureSizeAlign(
                        device,
                        desc,
                    );
                }

                pub fn textureSampleCountMax(
                    device: *Device,
                    desc: TextureDesc,
                ) callconv(@"callconv") u32 {
                    return functions.textureSampleCountMax(
                        device,
                        desc,
                    );
                }

                pub fn createTexture(
                    device: *Device,
                    desc: TextureDesc,
                    memory: DeviceAddress,
                    texture: **Texture,
                ) callconv(@"callconv") Result {
                    return cResult(functions.createTexture(
                        device,
                        desc,
                        memory,
                        texture,
                    ));
                }

                pub fn destroyTexture(
                    texture: *Texture,
                ) callconv(@"callconv") void {
                    return functions.destroyTexture(
                        texture,
                    );
                }

                pub fn textureStorageDescriptor(
                    texture: *Texture,
                    desc: TextureViewDesc,
                    descriptor: *Descriptor,
                ) callconv(@"callconv") Result {
                    return cResult(functions.textureStorageDescriptor(
                        texture,
                        desc,
                        descriptor,
                    ));
                }

                pub fn textureViewDescriptor(
                    texture: *Texture,
                    desc: TextureViewDesc,
                    descriptor: *Descriptor,
                ) callconv(@"callconv") Result {
                    return cResult(functions.textureViewDescriptor(
                        texture,
                        desc,
                        descriptor,
                    ));
                }

                pub fn createComputePipeline(
                    device: *Device,
                    ir_size: usize,
                    ir: [*]const u8,
                    pipeline: **Pipeline,
                ) callconv(@"callconv") Result {
                    return cResult(functions.createComputePipeline(
                        device,
                        ir_size,
                        ir,
                        pipeline,
                    ));
                }

                pub fn createGraphicsPipeline(
                    device: *Device,
                    vertex_ir_size: usize,
                    vertex_ir: [*]const u8,
                    pixel_ir_size: usize,
                    pixel_ir: [*]const u8,
                    desc: GraphicsPipelineDesc,
                    pipeline: **Pipeline,
                ) callconv(@"callconv") Result {
                    return cResult(functions.createGraphicsPipeline(
                        device,
                        vertex_ir_size,
                        vertex_ir,
                        pixel_ir_size,
                        pixel_ir,
                        desc,
                        pipeline,
                    ));
                }

                pub fn destroyPipeline(
                    pipeline: *Pipeline,
                ) callconv(@"callconv") void {
                    return functions.destroyPipeline(
                        pipeline,
                    );
                }

                pub fn createBlendState(
                    device: *Device,
                    desc: BlendDesc,
                    blend_state: **BlendState,
                ) callconv(@"callconv") Result {
                    return cResult(functions.createBlendState(
                        device,
                        desc,
                        blend_state,
                    ));
                }

                pub fn destroyBlendState(
                    blend_state: *BlendState,
                ) callconv(@"callconv") void {
                    return functions.destroyBlendState(
                        blend_state,
                    );
                }

                pub fn createDepthStencilState(
                    device: *Device,
                    desc: DepthStencilDesc,
                    depth_stencil_state: **DepthStencilState,
                ) callconv(@"callconv") Result {
                    return cResult(functions.createDepthStencilState(
                        device,
                        desc,
                        depth_stencil_state,
                    ));
                }

                pub fn destroyDepthStencilState(
                    depth_stencil_state: *DepthStencilState,
                ) callconv(@"callconv") void {
                    return functions.destroyDepthStencilState(
                        depth_stencil_state,
                    );
                }
            };
        }

        pub fn symbolMap(comptime functions: Functions) std.StaticStringMap(*const anyopaque) {
            const c_functions = CFunctions(functions);
            return .initComptime(@as([]const struct { []const u8, *const anyopaque }, &.{
                .{ "scAdapterInfo", @ptrCast(&c_functions.adapterInfo) },
                .{ "scCreateSurfaceWin32", @ptrCast(&c_functions.createSurfaceWin32) },
                .{ "scCreateSurfaceXlib", @ptrCast(&c_functions.createSurfaceXlib) },
                .{ "scDestroySurface", @ptrCast(&c_functions.destroySurface) },
                .{ "scSurfaceSupportedUsage", @ptrCast(&c_functions.surfaceSupportedUsage) },
                .{ "scSurfaceSupportedFormats", @ptrCast(&c_functions.surfaceSupportedFormats) },
                .{ "scSurfacePresentModes", @ptrCast(&c_functions.surfacePresentModes) },
                .{ "scHostFromDevicePointer", @ptrCast(&c_functions.hostFromDevicePointer) },
                .{ "scAlloc", @ptrCast(&c_functions.alloc) },
                .{ "scFree", @ptrCast(&c_functions.free) },
                .{ "scDescriptorSizeAndHeapAlign", @ptrCast(&c_functions.descriptorSizeAndHeapAlign) },
                .{ "scGetQueue", @ptrCast(&c_functions.getQueue) },
                .{ "scTextureCopyGranularity", @ptrCast(&c_functions.textureCopyGranularity) },
                .{ "scCreateCommandPool", @ptrCast(&c_functions.createCommandPool) },
                .{ "scDestroyCommandPool", @ptrCast(&c_functions.destroyCommandPool) },
                .{ "scResetCommandPool", @ptrCast(&c_functions.resetCommandPool) },
                .{ "scStartCommandRecording", @ptrCast(&c_functions.startCommandRecording) },
                .{ "scSubmit", @ptrCast(&c_functions.submit) },
                .{ "scSubmitAndSignal", @ptrCast(&c_functions.submitAndSignal) },
                .{ "scCreateTimeline", @ptrCast(&c_functions.createTimeline) },
                .{ "scDestroyTimeline", @ptrCast(&c_functions.destroyTimeline) },
                .{ "scWaitTimelinePoint", @ptrCast(&c_functions.waitTimelinePoint) },
                .{ "scCreateSwapchain", @ptrCast(&c_functions.createSwapchain) },
                .{ "scDestroySwapchain", @ptrCast(&c_functions.destroySwapchain) },
                .{ "scAcquireBackBuffer", @ptrCast(&c_functions.acquireBackBuffer) },
                .{ "scPresent", @ptrCast(&c_functions.present) },
                .{ "scSetActiveTextureHeap", @ptrCast(&c_functions.setActiveTextureHeap) },
                .{ "scSetDepthStencilState", @ptrCast(&c_functions.setDepthStencilState) },
                .{ "scSetBlendState", @ptrCast(&c_functions.setBlendState) },
                .{ "scSetPipeline", @ptrCast(&c_functions.setPipeline) },
                .{ "scDispatch", @ptrCast(&c_functions.dispatch) },
                .{ "scDispatchIndirect", @ptrCast(&c_functions.dispatchIndirect) },
                .{ "scBarrier", @ptrCast(&c_functions.barrier) },
                .{ "scCopyTextureToMemory", @ptrCast(&c_functions.copyTextureToMemory) },
                .{ "scCopyMemoryToTexture", @ptrCast(&c_functions.copyMemoryToTexture) },
                .{ "scCopyMemory", @ptrCast(&c_functions.copyMemory) },
                .{ "scBeginRenderPass", @ptrCast(&c_functions.beginRenderPass) },
                .{ "scEndRenderPass", @ptrCast(&c_functions.endRenderPass) },
                .{ "scSetScissor", @ptrCast(&c_functions.setScissor) },
                .{ "scSetViewport", @ptrCast(&c_functions.setViewport) },
                .{ "scDraw", @ptrCast(&c_functions.draw) },
                .{ "scDrawIndexed", @ptrCast(&c_functions.drawIndexed) },
                .{ "scDrawIndexedInstanced", @ptrCast(&c_functions.drawIndexedInstanced) },
                .{ "scDrawIndexedInstancedIndirect", @ptrCast(&c_functions.drawIndexedInstancedIndirect) },
                .{ "scDrawIndirect", @ptrCast(&c_functions.drawIndirect) },
                .{ "scTextureSizeAlign", @ptrCast(&c_functions.textureSizeAlign) },
                .{ "scTextureSampleCountMax", @ptrCast(&c_functions.textureSampleCountMax) },
                .{ "scCreateTexture", @ptrCast(&c_functions.createTexture) },
                .{ "scDestroyTexture", @ptrCast(&c_functions.destroyTexture) },
                .{ "scTextureStorageDescriptor", @ptrCast(&c_functions.textureStorageDescriptor) },
                .{ "scTextureViewDescriptor", @ptrCast(&c_functions.textureViewDescriptor) },
                .{ "scCreateComputePipeline", @ptrCast(&c_functions.createComputePipeline) },
                .{ "scCreateGraphicsPipeline", @ptrCast(&c_functions.createGraphicsPipeline) },
                .{ "scDestroyPipeline", @ptrCast(&c_functions.destroyPipeline) },
                .{ "scCreateBlendState", @ptrCast(&c_functions.createBlendState) },
                .{ "scDestroyBlendState", @ptrCast(&c_functions.destroyBlendState) },
                .{ "scCreateDepthStencilState", @ptrCast(&c_functions.createDepthStencilState) },
                .{ "scDestroyDepthStencilState", @ptrCast(&c_functions.destroyDepthStencilState) },
            }));
        }
    };
}
