const std = @import("std");
const c = @import("c.zig");
const gl = @import("gl/gl.zig");
const glfw = @import("glfw/glfw.zig");
const Particles = @import("particles/Particles.zig");

pub const log_level = std.log.Level.info;
pub const allocator = std.heap.c_allocator;

pub fn main() !void {
  std.log.info("Glad v{s}", .{ c.GLAD_GENERATOR_VERSION });
  std.log.info("GLFW v{s}", .{ c.glfwGetVersionString() });
  std.log.info("Dear ImGui v{s}", .{ c.igGetVersion() });

  try glfw.init(&.{});
  defer glfw.deinit();

  var window = try glfw.Window.init(960, 540, "gpu experiments", &.{
    .{ c.GLFW_CONTEXT_VERSION_MAJOR, gl.major },
    .{ c.GLFW_CONTEXT_VERSION_MINOR, gl.minor },
    .{ c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE },
    .{ c.GLFW_OPENGL_DEBUG_CONTEXT, c.GLFW_TRUE },
  });
  defer window.deinit();

  var particles = try Particles.init(&window);
  defer particles.deinit();

  try particles.run();
}
