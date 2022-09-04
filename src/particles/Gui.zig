const c = @import("../c.zig");
const ImGui = @import("../imgui/ImGui.zig");
const Self = @This();

imgui: ImGui,
state: struct {
  air_drag: f32 = 0.1,
  wind_power: f32 = 25.0,
  wind_frequency: f32 = 1.0,
  wind_turbulence: f32 = 0.1,
  render_feedback: f32 = 0.9,
  render_opacity: f32 = 0.1,
} = .{},

pub fn init(window: *c.GLFWwindow) Self {
  const imgui = ImGui.init(window);
  imgui.io.IniFilename = null;
  imgui.initFonts();
  return .{ .imgui = imgui };
}

pub fn deinit(self: *const Self) void {
  self.imgui.deinit();
}

pub fn update(self: *const Self) void {
  self.imgui.newFrame();

  const fps: f64 = self.imgui.io.Framerate;

  _ = c.igBegin("gui", null, c.ImGuiWindowFlags_None);
  c.igText("%.3f ms/frame (%.1f fps)", 1000.0 / fps, fps);
  _ = c.igSliderFloat("air_drag", &self.state.air_drag, 0.0, 1.0, "%.3f", 0);
  _ = c.igSliderFloat("wind_power", &self.state.wind_power, 0.0, 100.0, "%.3f", 0);
  _ = c.igSliderFloat("wind_frequency", &self.state.wind_frequency, 0.0, 5.0, "%.3f", 0);
  _ = c.igSliderFloat("wind_turbulence", &self.state.wind_turbulence, 0.0, 1.0, "%.3f", 0);
  _ = c.igSliderFloat("render_feedback", &self.state.render_feedback, 0.0, 1.0, "%.3f", 0);
  _ = c.igSliderFloat("render_opacity", &self.state.render_opacity, 0.0, 1.0, "%.3f", 0);
  c.igEnd();

  // c.igShowDemoWindow(null);
}

pub fn render(self: *const Self) void {
  self.imgui.render();
}
