const std = @import("std");
const c = @import("c.zig");
const gl = @import("gl/gl.zig");
const glfw = @import("glfw/glfw.zig");
const App = @import("app/App.zig");

pub const allocator = std.heap.c_allocator;
pub const std_options = struct {
  pub const log_level = std.log.Level.info;
};

pub fn main() !void {
  std.log.info("Glad v{s}", .{ c.GLAD_GENERATOR_VERSION });
  std.log.info("GLFW v{s}", .{ c.glfwGetVersionString() });
  std.log.info("Dear ImGui v{s}", .{ c.igGetVersion() });

  try glfw.init(&.{});
  defer glfw.deinit();

  var window = try glfw.Window.init(1024, 768, "Flux", &.{
    .{ c.GLFW_CONTEXT_VERSION_MAJOR, gl.MAJOR },
    .{ c.GLFW_CONTEXT_VERSION_MINOR, gl.MINOR },
    .{ c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE },
    .{ c.GLFW_OPENGL_DEBUG_CONTEXT, c.GLFW_TRUE },
  });
  defer window.deinit();

  var app = try App.init(&window);
  defer app.deinit();

  try app.run();
}
