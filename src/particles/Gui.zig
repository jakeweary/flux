const c = @import("../c.zig");
const std = @import("std");
const ImGui = @import("../imgui/ImGui.zig");
const Particles = @import("Particles.zig");
const Self = @This();

imgui: ImGui,
debug: bool = false,

pub fn init(window: *c.GLFWwindow) Self {
  const imgui = ImGui.init(window);
  imgui.io.IniFilename = null;
  imgui.loadCustomStyle();
  imgui.loadCustomPixelFont();
  return .{ .imgui = imgui };
}

pub fn deinit(self: *const Self) void {
  self.imgui.deinit();
}

pub fn render(self: *const Self) void {
  self.imgui.render();
}

pub fn update(self: *Self, particles: *Particles) void {
  self.imgui.newFrame();
  self.menu(particles);

  if (self.debug)
    c.igShowDemoWindow(&self.debug);
}

// ---

fn menu(self: *Self, particles: *Particles) void {
  const window_flags = 0
    | c.ImGuiWindowFlags_AlwaysAutoResize
    | c.ImGuiWindowFlags_NoDecoration
    | c.ImGuiWindowFlags_NoMove;

  const tree_node_flags = 0
    | c.ImGuiTreeNodeFlags_DefaultOpen
    | c.ImGuiTreeNodeFlags_SpanAvailWidth;

  c.igSetNextWindowPos(.{ .x = 16, .y = 16 }, c.ImGuiCond_FirstUseEver, .{ .x = 0, .y = 0 });
  _ = c.igBegin("menu", null, window_flags);
  defer c.igEnd();

  const fr: f64 = self.imgui.io.Framerate;
  c.igText("%.1f fps · %.3f ms/frame", fr, 1000.0 / fr);

  if (c.igCollapsingHeader_TreeNodeFlags("settings", 0)) {
    c.igPushItemWidth(128);

    if (c.igTreeNodeEx_Str("simulation", tree_node_flags)) {
      _ = c.igSliderFloat("air resistance", &particles.cfg.air_resistance, 0.0, 1.0, null, 0);
      _ = c.igSliderFloat("wind power", &particles.cfg.wind_power, 0.0, 1.0, null, 0);
      _ = c.igSliderFloat("wind frequency", &particles.cfg.wind_frequency, 0.0, 1.0, null, 0);
      _ = c.igSliderFloat("wind turbulence", &particles.cfg.wind_turbulence, 0.0, 1.0, null, 0);
      _ = c.igCheckbox("walls collision", &particles.cfg.walls_collision);
      c.igTreePop();
    }

    if (c.igTreeNodeEx_Str("rendering", tree_node_flags)) {
      _ = c.igSliderFloat("feedback ratio", &particles.cfg.feedback_ratio, 0.0, 1.0, null, 0);
      _ = c.igSliderFloat("brightness", &particles.cfg.brightness, 0.0, 2.0, null, 0);
      c.igTreePop();
    }

    if (c.igTreeNodeEx_Str("performance", tree_node_flags)) {
      _ = c.igSliderInt("steps per frame", &particles.cfg.steps_per_frame, 1, 32, null, 0);
      _ = c.igSliderInt2("simulation size", &particles.cfg.simulation_size, 1, 2048, null, 0);
      if (c.igBeginTable("table", 3, c.ImGuiTableFlags_SizingStretchSame, .{ .x = 0, .y = 0 }, 0)) {
        const per_step = particles.cfg.simulation_size[0] * particles.cfg.simulation_size[1];
        const per_frame = per_step * particles.cfg.steps_per_frame;
        const per_second = @intToFloat(f64, per_frame) * fr;
        _ = c.igTableNextColumn(); c.igText("upd/step");
        _ = c.igTableNextColumn(); c.igText("upd/frame");
        _ = c.igTableNextColumn(); c.igText("upd/second");
        _ = c.igTableNextColumn(); c.igText("%d", per_step);
        _ = c.igTableNextColumn(); c.igText("%d", per_frame);
        _ = c.igTableNextColumn(); c.igText("%.0f", per_second);
        c.igEndTable();
      }
      c.igTreePop();
    }

    if (c.igTreeNodeEx_Str("misc.", tree_node_flags)) {
      if (c.igButton("defaults", .{ .x = 0, .y = 0 }))
        particles.cfg = .{};
      c.igSameLine(0, -1);
      if (c.igButton("fullscreen", .{ .x = 0, .y = 0 }))
        particles.window.fullscreen();
      c.igSameLine(0, -1);
      _ = c.igCheckbox("debug window", &self.debug);
      c.igTreePop();
    }
  }
}
