const c = @import("c.zig");
const std = @import("std");
const gl = @import("gl/gl.zig");
const Patricles = @import("particles/Patricles.zig");

pub const log_level = std.log.Level.info;
pub const allocator = std.heap.c_allocator;

pub fn main() !void {
  _ = c.glfwSetErrorCallback(gl.callbacks.onError);

  if (c.glfwInit() == c.GLFW_FALSE)
    return error.GLFW_InitError;
  defer c.glfwTerminate();

  c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, gl.major);
  c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, gl.minor);
  c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
  c.glfwWindowHint(c.GLFW_OPENGL_DEBUG_CONTEXT, c.GLFW_TRUE);
  c.glfwWindowHint(c.GLFW_RESIZABLE, c.GLFW_FALSE);
  // c.glfwWindowHint(c.GLFW_DECORATED, c.GLFW_FALSE);
  const window = c.glfwCreateWindow(1152, 648, "", null, null)
    orelse return error.GLFW_CreateWindowError;
  defer c.glfwDestroyWindow(window);

  _ = c.glfwSetWindowSizeCallback(window, gl.callbacks.onWindowSize);
  _ = c.glfwSetKeyCallback(window, gl.callbacks.onKey);
  c.glfwMakeContextCurrent(window);
  c.glfwSwapInterval(0);
  _ = c.gladLoadGL(c.glfwGetProcAddress);

  gl.debug.enableDebugMessages();

  // ---

  var particles = try Patricles.init();
  defer particles.deinit();

  try particles.run(window);
}
