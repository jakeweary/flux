const c = @import("../c.zig");
const std = @import("std");

pub const Window = @import("Window.zig");
pub const log = std.log.scoped(.glfw);

// ---

pub fn init(hints: []const [2]c_int) !void {
  _ = c.glfwSetErrorCallback(onError);

  for (hints) |*hint|
    c.glfwInitHint(hint[0], hint[1]);

  if (c.glfwInit() == c.GLFW_FALSE)
    return error.GLFW_InitError;
}

pub fn deinit() void {
  c.glfwTerminate();
}

// ---

pub fn onError(code: c_int, desc: [*c]const u8) callconv(.C) void {
  log.err("{s} ({})", .{ desc, code });
}

pub fn onKey(window: ?*c.GLFWwindow, key: c_int, _: c_int, action: c_int, _: c_int) callconv(.C) void {
  if (action == c.GLFW_PRESS and key == c.GLFW_KEY_ESCAPE)
    c.glfwSetWindowShouldClose(window, c.GLFW_TRUE);
}
