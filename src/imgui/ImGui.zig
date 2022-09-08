const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const imgui = @import("imgui.zig");
const Self = @This();

ctx: *c.ImGuiContext,
io: *c.ImGuiIO,
style: *c.ImGuiStyle,

pub fn init(window: *c.GLFWwindow) Self {
  const self = Self{
    .ctx = c.igCreateContext(null),
    .io = c.igGetIO(),
    .style = c.igGetStyle(),
  };
  _ = c.ImGui_ImplGlfw_InitForOpenGL(window, true);
  _ = c.ImGui_ImplOpenGL3_Init(gl.VERSION);
  return self;
}

pub fn deinit(self: *const Self) void {
  c.ImGui_ImplOpenGL3_Shutdown();
  c.ImGui_ImplGlfw_Shutdown();
  c.igDestroyContext(self.ctx);
}

pub fn newFrame(_: *const Self) void {
  c.ImGui_ImplOpenGL3_NewFrame();
  c.ImGui_ImplGlfw_NewFrame();
  c.igNewFrame();
}

pub fn render(_: *const Self) void {
  c.igRender();
  c.ImGui_ImplOpenGL3_RenderDrawData(c.igGetDrawData());
}
