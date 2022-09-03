const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const imgui = @import("./imgui.zig");
const Self = @This();

ctx: *c.ImGuiContext,
io: *c.ImGuiIO,

pub fn init(window: *c.GLFWwindow) Self {
  imgui.log.info("Dear ImGui v{s}", .{c.igGetVersion()});

  const ctx = c.igCreateContext(null);
  _ = c.ImGui_ImplGlfw_InitForOpenGL(window, true);
  _ = c.ImGui_ImplOpenGL3_Init(gl.version);
  return .{ .ctx = ctx, .io = c.igGetIO() };
}

pub fn deinit(self: *const Self) void {
  c.ImGui_ImplOpenGL3_Shutdown();
  c.ImGui_ImplGlfw_Shutdown();
  c.igDestroyContext(self.ctx);
}

pub fn initFonts(self: *const Self) void {
  var text_pixels: ?*u8 = null;
  var text_w: c_int = undefined;
  var text_h: c_int = undefined;
  c.ImFontAtlas_GetTexDataAsRGBA32(self.io.Fonts, &text_pixels, &text_w, &text_h, null);
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
