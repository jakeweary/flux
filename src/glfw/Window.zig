const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const glfw = @import("glfw.zig");
const Self = @This();

ptr: *c.GLFWwindow,
x: c_int = undefined,
y: c_int = undefined,
w: c_int = undefined,
h: c_int = undefined,

pub fn init(title: [*:0]const u8, w: c_int, h: c_int, hints: []const [2]c_int) !Self {
  for (hints) |*hint|
    c.glfwWindowHint(hint[0], hint[1]);

  const ptr = c.glfwCreateWindow(w, h, title, null, null)
    orelse return error.GLFW_CreateWindowError;
  errdefer c.glfwDestroyWindow(ptr);

  c.glfwMakeContextCurrent(ptr);
  if (c.gladLoadGL(c.glfwGetProcAddress) == 0)
    return error.GLAD_LoadError;

  gl.debug.enableDebugMessages();

  _ = c.glfwSetKeyCallback(ptr, glfw.onKey);

  return .{ .ptr = ptr };
}

pub fn deinit(self: *const Self) void {
  c.glfwDestroyWindow(self.ptr);
  c.glfwTerminate();
}

pub fn toggleFullscreen(self: *const Self) void {
  if (c.glfwGetWindowMonitor(self.ptr) != null)
    return self.restore();
  self.save();
  self.fullscreen();
}

// ---

fn fullscreen(self: *const Self) void {
  const monitor = c.glfwGetPrimaryMonitor().?;
  const mode = c.glfwGetVideoMode(monitor);
  c.glfwSetWindowMonitor(self.ptr, monitor, 0, 0, mode.*.width, mode.*.height, 0);
}

fn save(self: *const Self) void {
  c.glfwGetWindowPos(self.ptr, &self.x, &self.y);
  c.glfwGetWindowSize(self.ptr, &self.w, &self.h);
}

fn restore(self: *const Self) void {
  c.glfwSetWindowMonitor(self.ptr, null, self.x, self.y, self.w, self.h, 0);
}
