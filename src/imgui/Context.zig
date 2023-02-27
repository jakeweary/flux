const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const imgui = @import("imgui.zig");
const Self = @This();

ctx: *c.ImGuiContext,

pub fn init(window: *c.GLFWwindow, install_callbacks: bool) Self {
  const self = Self{ .ctx = c.igCreateContext(null) };
  _ = c.ImGui_ImplGlfw_InitForOpenGL(window, install_callbacks);
  _ = c.ImGui_ImplOpenGL3_Init(gl.VERSION);
  return self;
}

pub fn deinit(self: *const Self) void {
  c.ImGui_ImplOpenGL3_Shutdown();
  c.ImGui_ImplGlfw_Shutdown();
  c.igDestroyContext(self.ctx);
}
