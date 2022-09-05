const c = @import("../c.zig");
const ImGui = @import("../imgui/ImGui.zig");
const Particles = @import("Particles.zig");
const Self = @This();

imgui: ImGui,

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

pub fn update(self: *const Self, particles: *Particles) void {
  self.imgui.newFrame();
  self.menu(particles);
}

pub fn render(self: *const Self) void {
  self.imgui.render();
}

// ---

fn menu(self: *const Self, particles: *Particles) void {
  c.igSetNextWindowPos(.{ .x = 16, .y = 16 }, c.ImGuiCond_FirstUseEver, .{ .x = 0, .y = 0 });
  _ = c.igBegin("menu", null, 0
    | c.ImGuiWindowFlags_NoTitleBar
    | c.ImGuiWindowFlags_NoMove
    | c.ImGuiWindowFlags_AlwaysAutoResize);
  c.igPushItemWidth(128);

  const fr: f64 = self.imgui.io.Framerate;
  c.igText("%.1f fps · %.3f ms/frame", fr, 1000.0 / fr);

  if (c.igCollapsingHeader_TreeNodeFlags("settings", 0)) {
    c.igText("simulation");
    _ = c.igSliderFloat("air drag", &particles.cfg.air_drag, 0.0, 1.0, "%.3f", 0);
    _ = c.igSliderFloat("wind power", &particles.cfg.wind_power, 0.0, 100.0, "%.3f", 0);
    _ = c.igSliderFloat("wind frequency", &particles.cfg.wind_frequency, 0.0, 5.0, "%.3f", 0);
    _ = c.igSliderFloat("wind turbulence", &particles.cfg.wind_turbulence, 0.0, 1.0, "%.3f", 0);

    c.igText("render");
    _ = c.igSliderFloat("render feedback", &particles.cfg.render_feedback, 0.0, 1.0, "%.3f", 0);
    _ = c.igSliderFloat("render opacity", &particles.cfg.render_opacity, 0.0, 1.0, "%.3f", 0);

    c.igText("performance");
    _ = c.igSliderInt("steps per frame", &particles.cfg.steps_per_frame, 1, 32, "%d", 0);
  }

  if (c.igCollapsingHeader_TreeNodeFlags("actions", 0)) {
    if (c.igButton("toggle fullscreen", .{ .x = 0, .y = 0 })) {
      particles.window.toggleFullscreen();
    }
  }

  c.igEnd();
}
