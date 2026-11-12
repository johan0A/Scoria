// Generated file, do not edit.
// version: 0.1.0

const std = @import("std");
const sc = @import("sc_minimal.zig");

const HandleTypes = struct {
    Instance: type,
    Surface: type,
    Adapter: type,
    Device: type,
    Queue: type,
    Timeline: type,
    Swapchain: type,
    CommandBuffer: type,
    Texture: type,
    Pipeline: type,
    DepthStencilState: type,
};

fn Functions(handle_types: HandleTypes) type {
    return struct {
        adapterInfo: fn (
            instance: *handle_types.Instance,
            adapter: *handle_types.Adapter,
        ) sc.AdapterInfo,
        createSurfaceWin32: fn (
            device: *handle_types.Device,
            desc: sc.SurfaceWin32Desc,
        ) *handle_types.Surface,
        createSurfaceXlib: fn (
            device: *handle_types.Device,
            desc: sc.SurfaceXlibDesc,
        ) *handle_types.Surface,
        destroySurface: fn (
            surface: *handle_types.Surface,
        ) void,
        surfaceSupportedUsage: fn (
            surface: *handle_types.Surface,
        ) sc.TextureUsage,
        surfaceSupportedFormats: fn (
            surface: *handle_types.Surface,
            formats_capacity: usize,
            formats: ?[*]sc.Format,
            format_count: *usize,
        ) void,
        surfacePresentModes: fn (
            surface: *handle_types.Surface,
            present_modes_capacity: usize,
            present_modes: ?[*]sc.PresentMode,
            present_mode_count: *usize,
        ) void,
        hostFromDevicePointer: fn (
            device: *handle_types.Device,
            address: sc.DeviceAddress,
        ) *anyopaque,
        alloc: fn (
            device: *handle_types.Device,
            size: usize,
            alignment: usize,
            memory: sc.MemoryKind,
            device_mapping: *sc.HostDeviceAddress,
        ) error{
            OutOfMemory,
            OutOfDeviceMemory,
        }!void,
        free: fn (
            device: *handle_types.Device,
            address: sc.DeviceAddress,
        ) void,
        descriptorSizeAndHeapAlign: fn (
            device: *handle_types.Device,
        ) sc.SizeAlign,
        storeDescriptor: fn (
            device: *handle_types.Device,
            descriptor: *const sc.Descriptor,
            descriptor_heap: [*]u8,
            index: usize,
        ) void,
        getQueue: fn (
            device: *handle_types.Device,
            queue_kind: sc.QueueKind,
        ) *handle_types.Queue,
        startCommandRecording: fn (
            queue: *handle_types.Queue,
            command_buffer: **handle_types.CommandBuffer,
        ) error{
            OutOfMemory,
            OutOfDeviceMemory,
            Unknown,
        }!void,
        submit: fn (
            queue: *handle_types.Queue,
            command_buffer_count: usize,
            command_buffers: [*]const *handle_types.CommandBuffer,
        ) error{
            OutOfDeviceMemory,
            OutOfMemory,
            DeviceLost,
            Unknown,
        }!void,
        submitAndSignal: fn (
            queue: *handle_types.Queue,
            command_buffer_count: usize,
            command_buffers: [*]const *handle_types.CommandBuffer,
            signal: sc.TimelinePoint,
        ) error{
            OutOfDeviceMemory,
            OutOfMemory,
            DeviceLost,
            Unknown,
        }!void,
        createTimeline: fn (
            device: *handle_types.Device,
            initial_value: u64,
            timeline: **handle_types.Timeline,
        ) error{
            OutOfMemory,
            OutOfDeviceMemory,
            Unknown,
        }!void,
        destroyTimeline: fn (
            timeline: *handle_types.Timeline,
        ) void,
        waitTimelinePoint: fn (
            point: sc.TimelinePoint,
        ) error{
            OutOfDeviceMemory,
            OutOfMemory,
            DeviceLost,
            Unknown,
        }!void,
        createSwapchain: fn (
            queue: *handle_types.Queue,
            surface: *handle_types.Surface,
            desc: sc.SwapchainDesc,
            swapchain: **handle_types.Swapchain,
        ) error{
            OutOfDeviceMemory,
            OutOfMemory,
            SurfaceLost,
            Unknown,
        }!void,
        destroySwapchain: fn (
            swapchain: *handle_types.Swapchain,
        ) void,
        acquireBackBuffer: fn (
            swapchain: *handle_types.Swapchain,
            extent: sc.Extent2D,
            back_buffer: *sc.BackBuffer,
        ) error{
            OutOfMemory,
            OutOfDeviceMemory,
            DeviceLost,
            SurfaceLost,
            NoBackbuffer,
            Unknown,
        }!void,
        present: fn (
            swapchain: *handle_types.Swapchain,
        ) error{
            OutOfMemory,
            OutOfDeviceMemory,
            DeviceLost,
            SurfaceLost,
            Unknown,
        }!void,
        setActiveTextureHeap: fn (
            command_buffer: *handle_types.CommandBuffer,
            heap_address: sc.DeviceAddress,
        ) void,
        setDepthStencilState: fn (
            command_buffer: *handle_types.CommandBuffer,
            depth_stencil_state: *handle_types.DepthStencilState,
        ) void,
        setPipeline: fn (
            command_buffer: *handle_types.CommandBuffer,
            pipeline: *handle_types.Pipeline,
        ) void,
        dispatch: fn (
            command_buffer: *handle_types.CommandBuffer,
            data: sc.DeviceAddress,
            x: u32,
            y: u32,
            z: u32,
        ) void,
        dispatchIndirect: fn (
            command_buffer: *handle_types.CommandBuffer,
            data: sc.DeviceAddress,
            arguments: sc.DeviceAddress,
        ) void,
        barrier: fn (
            command_buffer: *handle_types.CommandBuffer,
            before: sc.Stage,
            after: sc.Stage,
            hazard: sc.Hazard,
        ) void,
        copyTextureToMemory: fn (
            command_buffer: *handle_types.CommandBuffer,
            source_texture: *handle_types.Texture,
            destination: sc.DeviceAddress,
            size: usize,
            desc: sc.TextureCopyDesc,
        ) void,
        copyMemoryToTexture: fn (
            command_buffer: *handle_types.CommandBuffer,
            source: sc.DeviceAddress,
            size: usize,
            destination_texture: *handle_types.Texture,
            desc: sc.TextureCopyDesc,
        ) void,
        copyMemory: fn (
            command_buffer: *handle_types.CommandBuffer,
            source: sc.DeviceAddress,
            destination: sc.DeviceAddress,
            size: usize,
        ) void,
        beginRenderPass: fn (
            command_buffer: *handle_types.CommandBuffer,
            desc: sc.RenderPassDesc,
        ) void,
        endRenderPass: fn (
            command_buffer: *handle_types.CommandBuffer,
        ) void,
        setScissor: fn (
            command_buffer: *handle_types.CommandBuffer,
            rect: sc.Rect2D,
        ) void,
        setViewport: fn (
            command_buffer: *handle_types.CommandBuffer,
            viewport: sc.Viewport,
        ) void,
        draw: fn (
            command_buffer: *handle_types.CommandBuffer,
            vertex_data: sc.DeviceAddress,
            pixel_data: sc.DeviceAddress,
            vertex_count: u32,
            instance_count: u32,
        ) void,
        drawIndexed: fn (
            command_buffer: *handle_types.CommandBuffer,
            vertex_data: sc.DeviceAddress,
            pixel_data: sc.DeviceAddress,
            index_type: sc.IndexType,
            indices: sc.DeviceAddress,
            index_count: u32,
        ) void,
        drawIndexedInstanced: fn (
            command_buffer: *handle_types.CommandBuffer,
            vertex_data: sc.DeviceAddress,
            pixel_data: sc.DeviceAddress,
            index_type: sc.IndexType,
            indices: sc.DeviceAddress,
            index_count: u32,
            instance_count: u32,
        ) void,
        drawIndexedInstancedIndirect: fn (
            command_buffer: *handle_types.CommandBuffer,
            vertex_data: sc.DeviceAddress,
            pixel_data: sc.DeviceAddress,
            index_type: sc.IndexType,
            indices: sc.DeviceAddress,
            arguments: sc.DeviceAddress,
            draw_count: u32,
        ) void,
        drawIndirect: fn (
            command_buffer: *handle_types.CommandBuffer,
            vertex_data: sc.DeviceAddress,
            pixel_data: sc.DeviceAddress,
            arguments: sc.DeviceAddress,
            draw_count: u32,
        ) void,
        textureSizeAlign: fn (
            device: *handle_types.Device,
            desc: sc.TextureDesc,
        ) sc.SizeAlign,
        createTexture: fn (
            device: *handle_types.Device,
            desc: sc.TextureDesc,
            data: sc.DeviceAddress,
            texture: **handle_types.Texture,
        ) error{
            OutOfMemory,
            OutOfDeviceMemory,
            Unknown,
        }!void,
        destroyTexture: fn (
            texture: *handle_types.Texture,
        ) void,
        textureStorageDescriptor: fn (
            texture: *handle_types.Texture,
            desc: sc.TextureViewDesc,
            descriptor: *sc.Descriptor,
        ) error{
            OutOfMemory,
            OutOfDeviceMemory,
            Unknown,
        }!void,
        textureViewDescriptor: fn (
            texture: *handle_types.Texture,
            desc: sc.TextureViewDesc,
            descriptor: *sc.Descriptor,
        ) error{
            OutOfMemory,
            OutOfDeviceMemory,
            Unknown,
        }!void,
        createComputePipeline: fn (
            device: *handle_types.Device,
            ir_size: usize,
            ir: [*]const u8,
            pipeline: **handle_types.Pipeline,
        ) error{
            OutOfMemory,
            OutOfDeviceMemory,
            MalformedScir,
            UnsupportedScirVersion,
            UnsupportedScirBytecode,
            Unknown,
        }!void,
        createGraphicsPipeline: fn (
            device: *handle_types.Device,
            vertex_ir_size: usize,
            vertex_ir: [*]const u8,
            pixel_ir_size: usize,
            pixel_ir: [*]const u8,
            desc: sc.GraphicsPipelineDesc,
            pipeline: **handle_types.Pipeline,
        ) error{
            OutOfMemory,
            OutOfDeviceMemory,
            MalformedScir,
            UnsupportedScirVersion,
            UnsupportedScirBytecode,
            Unknown,
        }!void,
        destroyPipeline: fn (
            pipeline: *handle_types.Pipeline,
        ) void,
        createDepthStencilState: fn (
            device: *handle_types.Device,
            desc: sc.DepthStencilDesc,
            depth_stencil_state: **handle_types.DepthStencilState,
        ) error{
            OutOfMemory,
        }!void,
        destroyDepthStencilState: fn (
            depth_stencil_state: *handle_types.DepthStencilState,
        ) void,
    };
}

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

fn cResult(result: anytype) sc.Result {
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

fn CFunctions(comptime handle_types: HandleTypes, comptime functions: Functions(handle_types)) type {
    return struct {
        pub fn adapterInfo(
            instance: *handle_types.Instance,
            adapter: *handle_types.Adapter,
        ) callconv(sc.@"callconv") sc.AdapterInfo {
            return functions.adapterInfo(
                instance,
                adapter,
            );
        }

        pub fn createSurfaceWin32(
            device: *handle_types.Device,
            desc: sc.SurfaceWin32Desc,
        ) callconv(sc.@"callconv") *handle_types.Surface {
            return functions.createSurfaceWin32(
                device,
                desc,
            );
        }

        pub fn createSurfaceXlib(
            device: *handle_types.Device,
            desc: sc.SurfaceXlibDesc,
        ) callconv(sc.@"callconv") *handle_types.Surface {
            return functions.createSurfaceXlib(
                device,
                desc,
            );
        }

        pub fn destroySurface(
            surface: *handle_types.Surface,
        ) callconv(sc.@"callconv") void {
            return functions.destroySurface(
                surface,
            );
        }

        pub fn surfaceSupportedUsage(
            surface: *handle_types.Surface,
        ) callconv(sc.@"callconv") sc.TextureUsage {
            return functions.surfaceSupportedUsage(
                surface,
            );
        }

        pub fn surfaceSupportedFormats(
            surface: *handle_types.Surface,
            formats_capacity: usize,
            formats: ?[*]sc.Format,
            format_count: *usize,
        ) callconv(sc.@"callconv") void {
            return functions.surfaceSupportedFormats(
                surface,
                formats_capacity,
                formats,
                format_count,
            );
        }

        pub fn surfacePresentModes(
            surface: *handle_types.Surface,
            present_modes_capacity: usize,
            present_modes: ?[*]sc.PresentMode,
            present_mode_count: *usize,
        ) callconv(sc.@"callconv") void {
            return functions.surfacePresentModes(
                surface,
                present_modes_capacity,
                present_modes,
                present_mode_count,
            );
        }

        pub fn hostFromDevicePointer(
            device: *handle_types.Device,
            address: sc.DeviceAddress,
        ) callconv(sc.@"callconv") *anyopaque {
            return functions.hostFromDevicePointer(
                device,
                address,
            );
        }

        pub fn alloc(
            device: *handle_types.Device,
            size: usize,
            alignment: usize,
            memory: sc.MemoryKind,
            device_mapping: *sc.HostDeviceAddress,
        ) callconv(sc.@"callconv") sc.Result {
            return cResult(functions.alloc(
                device,
                size,
                alignment,
                memory,
                device_mapping,
            ));
        }

        pub fn free(
            device: *handle_types.Device,
            address: sc.DeviceAddress,
        ) callconv(sc.@"callconv") void {
            return functions.free(
                device,
                address,
            );
        }

        pub fn descriptorSizeAndHeapAlign(
            device: *handle_types.Device,
        ) callconv(sc.@"callconv") sc.SizeAlign {
            return functions.descriptorSizeAndHeapAlign(
                device,
            );
        }

        pub fn storeDescriptor(
            device: *handle_types.Device,
            descriptor: *const sc.Descriptor,
            descriptor_heap: [*]u8,
            index: usize,
        ) callconv(sc.@"callconv") void {
            return functions.storeDescriptor(
                device,
                descriptor,
                descriptor_heap,
                index,
            );
        }

        pub fn getQueue(
            device: *handle_types.Device,
            queue_kind: sc.QueueKind,
        ) callconv(sc.@"callconv") *handle_types.Queue {
            return functions.getQueue(
                device,
                queue_kind,
            );
        }

        pub fn startCommandRecording(
            queue: *handle_types.Queue,
            command_buffer: **handle_types.CommandBuffer,
        ) callconv(sc.@"callconv") sc.Result {
            return cResult(functions.startCommandRecording(
                queue,
                command_buffer,
            ));
        }

        pub fn submit(
            queue: *handle_types.Queue,
            command_buffer_count: usize,
            command_buffers: [*]const *handle_types.CommandBuffer,
        ) callconv(sc.@"callconv") sc.Result {
            return cResult(functions.submit(
                queue,
                command_buffer_count,
                command_buffers,
            ));
        }

        pub fn submitAndSignal(
            queue: *handle_types.Queue,
            command_buffer_count: usize,
            command_buffers: [*]const *handle_types.CommandBuffer,
            signal: sc.TimelinePoint,
        ) callconv(sc.@"callconv") sc.Result {
            return cResult(functions.submitAndSignal(
                queue,
                command_buffer_count,
                command_buffers,
                signal,
            ));
        }

        pub fn createTimeline(
            device: *handle_types.Device,
            initial_value: u64,
            timeline: **handle_types.Timeline,
        ) callconv(sc.@"callconv") sc.Result {
            return cResult(functions.createTimeline(
                device,
                initial_value,
                timeline,
            ));
        }

        pub fn destroyTimeline(
            timeline: *handle_types.Timeline,
        ) callconv(sc.@"callconv") void {
            return functions.destroyTimeline(
                timeline,
            );
        }

        pub fn waitTimelinePoint(
            point: sc.TimelinePoint,
        ) callconv(sc.@"callconv") sc.Result {
            return cResult(functions.waitTimelinePoint(
                point,
            ));
        }

        pub fn createSwapchain(
            queue: *handle_types.Queue,
            surface: *handle_types.Surface,
            desc: sc.SwapchainDesc,
            swapchain: **handle_types.Swapchain,
        ) callconv(sc.@"callconv") sc.Result {
            return cResult(functions.createSwapchain(
                queue,
                surface,
                desc,
                swapchain,
            ));
        }

        pub fn destroySwapchain(
            swapchain: *handle_types.Swapchain,
        ) callconv(sc.@"callconv") void {
            return functions.destroySwapchain(
                swapchain,
            );
        }

        pub fn acquireBackBuffer(
            swapchain: *handle_types.Swapchain,
            extent: sc.Extent2D,
            back_buffer: *sc.BackBuffer,
        ) callconv(sc.@"callconv") sc.Result {
            return cResult(functions.acquireBackBuffer(
                swapchain,
                extent,
                back_buffer,
            ));
        }

        pub fn present(
            swapchain: *handle_types.Swapchain,
        ) callconv(sc.@"callconv") sc.Result {
            return cResult(functions.present(
                swapchain,
            ));
        }

        pub fn setActiveTextureHeap(
            command_buffer: *handle_types.CommandBuffer,
            heap_address: sc.DeviceAddress,
        ) callconv(sc.@"callconv") void {
            return functions.setActiveTextureHeap(
                command_buffer,
                heap_address,
            );
        }

        pub fn setDepthStencilState(
            command_buffer: *handle_types.CommandBuffer,
            depth_stencil_state: *handle_types.DepthStencilState,
        ) callconv(sc.@"callconv") void {
            return functions.setDepthStencilState(
                command_buffer,
                depth_stencil_state,
            );
        }

        pub fn setPipeline(
            command_buffer: *handle_types.CommandBuffer,
            pipeline: *handle_types.Pipeline,
        ) callconv(sc.@"callconv") void {
            return functions.setPipeline(
                command_buffer,
                pipeline,
            );
        }

        pub fn dispatch(
            command_buffer: *handle_types.CommandBuffer,
            data: sc.DeviceAddress,
            x: u32,
            y: u32,
            z: u32,
        ) callconv(sc.@"callconv") void {
            return functions.dispatch(
                command_buffer,
                data,
                x,
                y,
                z,
            );
        }

        pub fn dispatchIndirect(
            command_buffer: *handle_types.CommandBuffer,
            data: sc.DeviceAddress,
            arguments: sc.DeviceAddress,
        ) callconv(sc.@"callconv") void {
            return functions.dispatchIndirect(
                command_buffer,
                data,
                arguments,
            );
        }

        pub fn barrier(
            command_buffer: *handle_types.CommandBuffer,
            before: sc.Stage,
            after: sc.Stage,
            hazard: sc.Hazard,
        ) callconv(sc.@"callconv") void {
            return functions.barrier(
                command_buffer,
                before,
                after,
                hazard,
            );
        }

        pub fn copyTextureToMemory(
            command_buffer: *handle_types.CommandBuffer,
            source_texture: *handle_types.Texture,
            destination: sc.DeviceAddress,
            size: usize,
            desc: sc.TextureCopyDesc,
        ) callconv(sc.@"callconv") void {
            return functions.copyTextureToMemory(
                command_buffer,
                source_texture,
                destination,
                size,
                desc,
            );
        }

        pub fn copyMemoryToTexture(
            command_buffer: *handle_types.CommandBuffer,
            source: sc.DeviceAddress,
            size: usize,
            destination_texture: *handle_types.Texture,
            desc: sc.TextureCopyDesc,
        ) callconv(sc.@"callconv") void {
            return functions.copyMemoryToTexture(
                command_buffer,
                source,
                size,
                destination_texture,
                desc,
            );
        }

        pub fn copyMemory(
            command_buffer: *handle_types.CommandBuffer,
            source: sc.DeviceAddress,
            destination: sc.DeviceAddress,
            size: usize,
        ) callconv(sc.@"callconv") void {
            return functions.copyMemory(
                command_buffer,
                source,
                destination,
                size,
            );
        }

        pub fn beginRenderPass(
            command_buffer: *handle_types.CommandBuffer,
            desc: sc.RenderPassDesc,
        ) callconv(sc.@"callconv") void {
            return functions.beginRenderPass(
                command_buffer,
                desc,
            );
        }

        pub fn endRenderPass(
            command_buffer: *handle_types.CommandBuffer,
        ) callconv(sc.@"callconv") void {
            return functions.endRenderPass(
                command_buffer,
            );
        }

        pub fn setScissor(
            command_buffer: *handle_types.CommandBuffer,
            rect: sc.Rect2D,
        ) callconv(sc.@"callconv") void {
            return functions.setScissor(
                command_buffer,
                rect,
            );
        }

        pub fn setViewport(
            command_buffer: *handle_types.CommandBuffer,
            viewport: sc.Viewport,
        ) callconv(sc.@"callconv") void {
            return functions.setViewport(
                command_buffer,
                viewport,
            );
        }

        pub fn draw(
            command_buffer: *handle_types.CommandBuffer,
            vertex_data: sc.DeviceAddress,
            pixel_data: sc.DeviceAddress,
            vertex_count: u32,
            instance_count: u32,
        ) callconv(sc.@"callconv") void {
            return functions.draw(
                command_buffer,
                vertex_data,
                pixel_data,
                vertex_count,
                instance_count,
            );
        }

        pub fn drawIndexed(
            command_buffer: *handle_types.CommandBuffer,
            vertex_data: sc.DeviceAddress,
            pixel_data: sc.DeviceAddress,
            index_type: sc.IndexType,
            indices: sc.DeviceAddress,
            index_count: u32,
        ) callconv(sc.@"callconv") void {
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
            command_buffer: *handle_types.CommandBuffer,
            vertex_data: sc.DeviceAddress,
            pixel_data: sc.DeviceAddress,
            index_type: sc.IndexType,
            indices: sc.DeviceAddress,
            index_count: u32,
            instance_count: u32,
        ) callconv(sc.@"callconv") void {
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
            command_buffer: *handle_types.CommandBuffer,
            vertex_data: sc.DeviceAddress,
            pixel_data: sc.DeviceAddress,
            index_type: sc.IndexType,
            indices: sc.DeviceAddress,
            arguments: sc.DeviceAddress,
            draw_count: u32,
        ) callconv(sc.@"callconv") void {
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
            command_buffer: *handle_types.CommandBuffer,
            vertex_data: sc.DeviceAddress,
            pixel_data: sc.DeviceAddress,
            arguments: sc.DeviceAddress,
            draw_count: u32,
        ) callconv(sc.@"callconv") void {
            return functions.drawIndirect(
                command_buffer,
                vertex_data,
                pixel_data,
                arguments,
                draw_count,
            );
        }

        pub fn textureSizeAlign(
            device: *handle_types.Device,
            desc: sc.TextureDesc,
        ) callconv(sc.@"callconv") sc.SizeAlign {
            return functions.textureSizeAlign(
                device,
                desc,
            );
        }

        pub fn createTexture(
            device: *handle_types.Device,
            desc: sc.TextureDesc,
            data: sc.DeviceAddress,
            texture: **handle_types.Texture,
        ) callconv(sc.@"callconv") sc.Result {
            return cResult(functions.createTexture(
                device,
                desc,
                data,
                texture,
            ));
        }

        pub fn destroyTexture(
            texture: *handle_types.Texture,
        ) callconv(sc.@"callconv") void {
            return functions.destroyTexture(
                texture,
            );
        }

        pub fn textureStorageDescriptor(
            texture: *handle_types.Texture,
            desc: sc.TextureViewDesc,
            descriptor: *sc.Descriptor,
        ) callconv(sc.@"callconv") sc.Result {
            return cResult(functions.textureStorageDescriptor(
                texture,
                desc,
                descriptor,
            ));
        }

        pub fn textureViewDescriptor(
            texture: *handle_types.Texture,
            desc: sc.TextureViewDesc,
            descriptor: *sc.Descriptor,
        ) callconv(sc.@"callconv") sc.Result {
            return cResult(functions.textureViewDescriptor(
                texture,
                desc,
                descriptor,
            ));
        }

        pub fn createComputePipeline(
            device: *handle_types.Device,
            ir_size: usize,
            ir: [*]const u8,
            pipeline: **handle_types.Pipeline,
        ) callconv(sc.@"callconv") sc.Result {
            return cResult(functions.createComputePipeline(
                device,
                ir_size,
                ir,
                pipeline,
            ));
        }

        pub fn createGraphicsPipeline(
            device: *handle_types.Device,
            vertex_ir_size: usize,
            vertex_ir: [*]const u8,
            pixel_ir_size: usize,
            pixel_ir: [*]const u8,
            desc: sc.GraphicsPipelineDesc,
            pipeline: **handle_types.Pipeline,
        ) callconv(sc.@"callconv") sc.Result {
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
            pipeline: *handle_types.Pipeline,
        ) callconv(sc.@"callconv") void {
            return functions.destroyPipeline(
                pipeline,
            );
        }

        pub fn createDepthStencilState(
            device: *handle_types.Device,
            desc: sc.DepthStencilDesc,
            depth_stencil_state: **handle_types.DepthStencilState,
        ) callconv(sc.@"callconv") sc.Result {
            return cResult(functions.createDepthStencilState(
                device,
                desc,
                depth_stencil_state,
            ));
        }

        pub fn destroyDepthStencilState(
            depth_stencil_state: *handle_types.DepthStencilState,
        ) callconv(sc.@"callconv") void {
            return functions.destroyDepthStencilState(
                depth_stencil_state,
            );
        }
    };
}

pub fn map(
    comptime handle_types: HandleTypes,
    comptime functions: Functions(handle_types),
) std.StaticStringMap(*const anyopaque) {
    const c_functions = CFunctions(handle_types, functions);
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
        .{ "scStoreDescriptor", @ptrCast(&c_functions.storeDescriptor) },
        .{ "scGetQueue", @ptrCast(&c_functions.getQueue) },
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
        .{ "scCreateTexture", @ptrCast(&c_functions.createTexture) },
        .{ "scDestroyTexture", @ptrCast(&c_functions.destroyTexture) },
        .{ "scTextureStorageDescriptor", @ptrCast(&c_functions.textureStorageDescriptor) },
        .{ "scTextureViewDescriptor", @ptrCast(&c_functions.textureViewDescriptor) },
        .{ "scCreateComputePipeline", @ptrCast(&c_functions.createComputePipeline) },
        .{ "scCreateGraphicsPipeline", @ptrCast(&c_functions.createGraphicsPipeline) },
        .{ "scDestroyPipeline", @ptrCast(&c_functions.destroyPipeline) },
        .{ "scCreateDepthStencilState", @ptrCast(&c_functions.createDepthStencilState) },
        .{ "scDestroyDepthStencilState", @ptrCast(&c_functions.destroyDepthStencilState) },
    }));
}
