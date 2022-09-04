const c = @import("../c.zig");
const ImGui = @import("../imgui/ImGui.zig");
const Self = @This();

imgui: ImGui,
state: struct {
  air_drag: f32 = 0.1,
  wind_power: f32 = 15.0,
  wind_frequency: f32 = 0.75,
  wind_turbulence: f32 = 0.05,
  render_feedback: f32 = 0.9,
  render_opacity: f32 = 0.1,
  steps_per_frame: c_int = 4,
} = .{},

pub fn init(window: *c.GLFWwindow) Self {
  const imgui = ImGui.init(window);

  imgui.io.IniFilename = null;

  imgui.style.WindowPadding = .{ .x = 8, .y = 8 };
  imgui.style.FramePadding = .{ .x = 2, .y = 2 };
  imgui.style.WindowBorderSize = 0;
  imgui.style.WindowRounding = 4;
  imgui.style.FrameRounding = 2;
  imgui.style.GrabRounding = 1;
  imgui.style.GrabMinSize = 4;

  const cfg = c.ImFontConfig_ImFontConfig();
  defer c.ImFontConfig_destroy(cfg);
  cfg.*.FontDataOwnedByAtlas = false;

  const ttf = @embedFile("../../deps/assets/fonts/ProggyTiny.ttf");
  _ = c.ImFontAtlas_AddFontFromMemoryTTF(imgui.io.Fonts, ttf, ttf.len, 10, cfg, null);
  _ = c.ImFontAtlas_Build(imgui.io.Fonts);

  return .{ .imgui = imgui };
}

pub fn deinit(self: *const Self) void {
  self.imgui.deinit();
}

pub fn update(self: *const Self) void {
  self.imgui.newFrame();
  self.main();
  // c.igShowDemoWindow(null);
}

pub fn render(self: *const Self) void {
  self.imgui.render();
}

// ---

fn main(self: *const Self) void {
  c.igSetNextWindowPos(.{ .x = 16, .y = 16 }, c.ImGuiCond_FirstUseEver, .{ .x = 0, .y = 0 });
  _ = c.igBegin("main", null, 0
    | c.ImGuiWindowFlags_NoTitleBar
    | c.ImGuiWindowFlags_NoMove
    | c.ImGuiWindowFlags_AlwaysAutoResize);
  c.igPushItemWidth(100);

  const fr: f64 = self.imgui.io.Framerate;
  c.igText("%.1f fps · %.3f ms/frame", fr, 1000.0 / fr);

  if (c.igCollapsingHeader_TreeNodeFlags("settings", 0)) {
    c.igText("simulation");
    _ = c.igSliderFloat("air drag", &self.state.air_drag, 0.0, 1.0, "%.3f", 0);
    _ = c.igSliderFloat("wind power", &self.state.wind_power, 0.0, 100.0, "%.3f", 0);
    _ = c.igSliderFloat("wind frequency", &self.state.wind_frequency, 0.0, 5.0, "%.3f", 0);
    _ = c.igSliderFloat("wind turbulence", &self.state.wind_turbulence, 0.0, 1.0, "%.3f", 0);

    c.igText("render");
    _ = c.igSliderFloat("render feedback", &self.state.render_feedback, 0.0, 1.0, "%.3f", 0);
    _ = c.igSliderFloat("render opacity", &self.state.render_opacity, 0.0, 1.0, "%.3f", 0);

    c.igText("performance");
    _ = c.igSliderInt("steps per frame", &self.state.steps_per_frame, 1, 32, "%d", 0);
  }

  c.igEnd();
}
