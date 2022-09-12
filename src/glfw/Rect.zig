const c = @import("../c.zig");
const Self = @This();

x: c_int,
y: c_int,
w: c_int,
h: c_int,

pub fn ofWindow(ptr: *c.GLFWwindow) Self {
  var self: Self = undefined;
  c.glfwGetWindowPos(ptr, &self.x, &self.y);
  c.glfwGetWindowSize(ptr, &self.w, &self.h);
  return self;
}

pub fn ofMonitor(ptr: *c.GLFWmonitor) Self {
  var self: Self = undefined;
  c.glfwGetMonitorPos(ptr, &self.x, &self.y);
  const mode: *c.GLFWvidmode = c.glfwGetVideoMode(ptr);
  return .{ .x = self.x, .y = self.y, .w = mode.width, .h = mode.height };
}

pub fn overlap(a: *const Self, b: *const Self) c_int {
  const x = overlap1d(a.x, a.x + a.w, b.x, b.x + b.w);
  const y = overlap1d(a.y, a.y + a.h, b.y, b.y + b.h);
  return x * y;
}

inline fn overlap1d(min1: c_int, max1: c_int, min2: c_int, max2: c_int) c_int {
  return @maximum(0, @minimum(max1, max2) - @maximum(min1, min2));
}