const builtin = @import("builtin");
const sc = @import("scoria");
const c = @import("c");

pub fn createSurface(device: *sc.Device, window: *c.SDL_Window) error{NativeWindowUnavailable}!*sc.Surface {
    const properties = c.SDL_GetWindowProperties(window);
    switch (builtin.os.tag) {
        .windows => return .createWin32(device, .{
            .hinstance = c.SDL_GetPointerProperty(properties, c.SDL_PROP_WINDOW_WIN32_INSTANCE_POINTER, null) orelse return error.NativeWindowUnavailable,
            .hwnd = c.SDL_GetPointerProperty(properties, c.SDL_PROP_WINDOW_WIN32_HWND_POINTER, null) orelse return error.NativeWindowUnavailable,
        }),
        else => {
            const x11_window = c.SDL_GetNumberProperty(properties, c.SDL_PROP_WINDOW_X11_WINDOW_NUMBER, 0);
            if (x11_window == 0) return error.NativeWindowUnavailable;
            return .createXlib(device, .{
                .display = c.SDL_GetPointerProperty(properties, c.SDL_PROP_WINDOW_X11_DISPLAY_POINTER, null) orelse return error.NativeWindowUnavailable,
                .window = @intCast(x11_window),
            });
        },
    }
}
