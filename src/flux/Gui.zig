const c = @import("../c.zig");
const std = @import("std");
const imgui = @import("../imgui/imgui.zig");
const Flux = @import("Flux.zig");
const Self = @This();

ctx: imgui.Context,
debug: bool = false,
fps: [60]f32 = .{ 0 } ** 60,
dt: [60]f32 = .{ 0 } ** 60,

pub fn init(window: *c.GLFWwindow) Self {
  const self = Self{ .ctx = imgui.Context.init(window) };
  imgui.io().IniFilename = null;
  imgui.io().ConfigWindowsMoveFromTitleBarOnly = true;
  imgui.loadCustomStyle();
  imgui.loadCustomPixelFont();
  return self;
}

pub fn deinit(self: *const Self) void {
  self.ctx.deinit();
}

pub fn render(_: *const Self) void {
  imgui.render();
}

pub fn update(self: *Self, flux: *Flux) void {
  imgui.newFrame();
  self.menu(flux);

  if (self.debug)
    c.igShowDemoWindow(&self.debug);
}

// ---

fn menu(self: *Self, flux: *Flux) void {
  const cfg = &flux.cfg;
  const window_flags = c.ImGuiWindowFlags_AlwaysAutoResize;
  const tree_node_flags = c.ImGuiTreeNodeFlags_SpanAvailWidth | c.ImGuiTreeNodeFlags_DefaultOpen;

  // c.igSetNextWindowCollapsed(true, c.ImGuiCond_FirstUseEver);
  c.igSetNextWindowPos(.{ .x = 16, .y = 16 }, c.ImGuiCond_FirstUseEver, .{ .x = 0, .y = 0 });
  _ = c.igBegin("Menu", null, window_flags);
  defer c.igEnd();

  c.igPushItemWidth(128);
  defer c.igPopItemWidth();

  if (c.igTreeNodeEx_Str("Scaling", tree_node_flags)) {
    _ = c.igSliderFloat("Time scale", &cfg.time_scale, 0.001, 1.0, null, 0);
    _ = c.igSliderFloat("Space scale", &cfg.space_scale, 0.001, 1.0, null, 0);
    c.igTreePop();
  }

  if (c.igTreeNodeEx_Str("Simulation", tree_node_flags)) {
    const defs = &flux.programs.update.defs;
    _ = c.igSliderFloat("Air resistance", &cfg.air_resistance, 0.0, 1.0, null, 0);
    _ = c.igSliderFloat("Flux power", &cfg.flux_power, 0.0, 1.0, null, 0);
    _ = c.igSliderFloat("Flux turbulence", &cfg.flux_turbulence, 0.0, 1.0, null, 0);
    _ = c.igCheckbox("Walls collision", &defs.WALLS_COLLISION);
    c.igTreePop();
  }

  if (c.igTreeNodeEx_Str("Rendering", tree_node_flags)) {
    const defs = &flux.programs.render.defs;
    _ = c.igCheckbox("Render as lines", &defs.RENDER_AS_LINES);
    if (defs.RENDER_AS_LINES) {
      _ = c.igCheckbox("Dynamic line brightness", &defs.DYNAMIC_LINE_BRIGHTNESS);
    }
    else {
      _ = c.igCheckbox("Fancy point rendering", &defs.FANCY_POINT_RENDERING);
      if (defs.FANCY_POINT_RENDERING)
        _ = c.igSliderFloat("Point scale", &cfg.point_scale, 1.0, 10.0, null, 0);
    }
    _ = c.igSliderFloat("Smooth spawn", &cfg.smooth_spawn, 0.0, 1.0, "%.2fs", 0);
    _ = c.igSliderFloat("Feedback mix", &cfg.feedback, 0.0, 1.0, null, 0);
    c.igTreePop();
  }

  if (c.igTreeNodeEx_Str("Post-processing", tree_node_flags)) {
    const blur = &flux.programs.bloom_blur;
    const post = &flux.programs.postprocess;
    _ = c.igSliderFloat("Brightness", &cfg.brightness, 0.0, 5.0, null, 0);
    _ = c.igSliderFloat("Bloom mix", &cfg.bloom, 0.0, 1.0, null, 0);
    _ = c.igSliderFloat("Bloom radius", &blur.defs.SIGMA, 1.0, 5.0, null, 0);
    _ = c.igCheckbox("ACES filmic tone mapping", &post.defs.ACES_TONEMAPPING);
    c.igTreePop();
  }

  if (c.igTreeNodeEx_Str("Performance", tree_node_flags)) {
    _ = c.igSliderInt("Steps per frame", &cfg.steps_per_frame, 1, 8, null, 0);
    _ = c.igSliderInt2("Simulation size", &cfg.simulation_size, 1, 2048, null, 0);
    _ = c.igCheckbox("Vertical synchronization", &cfg.vsync);
    c.igTreePop();
  }

  if (c.igTreeNodeEx_Str("Metrics", tree_node_flags)) {
    plot("%.1f fps", imgui.io().Framerate, &self.fps);
    plot("%.1f ms/frame", 1e3 * imgui.io().DeltaTime, &self.dt);
    if (c.igBeginTable("table", 3, c.ImGuiTableFlags_SizingStretchSame, .{ .x = 0, .y = 0 }, 0)) {
      const per_step = cfg.simulation_size[0] * cfg.simulation_size[1];
      const per_frame = per_step * cfg.steps_per_frame;
      const per_second = @intToFloat(f64, per_frame) * imgui.io().Framerate;
      _ = c.igTableNextColumn(); c.igText("ops/step"); imgui.hint("particle updates per step");
      _ = c.igTableNextColumn(); c.igText("ops/frame"); imgui.hint("particle updates per frame");
      _ = c.igTableNextColumn(); c.igText("ops/sec."); imgui.hint("particle updates per second");
      _ = c.igTableNextColumn(); c.igText("%d", per_step);
      _ = c.igTableNextColumn(); c.igText("%d", per_frame);
      _ = c.igTableNextColumn(); c.igText("%.0f", per_second);
      c.igEndTable();
    }
    c.igTreePop();
  }

  if (c.igTreeNodeEx_Str("Debug", tree_node_flags)) {
    _ = c.igSliderInt("Bloom layer", &cfg.bloom_layer, 1, 8, null, 0);
    _ = c.igSliderInt("Bloom sublayer", &cfg.bloom_sublayer, 1, 2, null, 0);
    c.igTreePop();
  }

  if (c.igTreeNodeEx_Str("Misc.", tree_node_flags)) {
    if (c.igButton("Defaults", .{ .x = 0, .y = 0 }))
      flux.defaults();
    c.igSameLine(0, -1);
    if (c.igButton("Fullscreen", .{ .x = 0, .y = 0 }))
      flux.window.fullscreen();
    c.igSameLine(0, -1);
    _ = c.igCheckbox("Demo window", &self.debug);
    c.igTreePop();
  }
}

fn plot(fmt: [*:0]const u8, value: f32, storage: []f32) void {
  storage[0] = value;
  std.mem.rotate(f32, storage, 1);
  c.igPlotLines_FloatPtr("", storage.ptr, @intCast(c_int, storage.len),
    0, null, 0, c.igGET_FLT_MAX(), .{ .x = 0, .y = 0 }, @sizeOf(f32));
  c.igSameLine(0, -1);
  c.igText(fmt, @as(f64, value));
}
