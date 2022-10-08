const c = @import("../c.zig");
const std = @import("std");
const imgui = @import("../imgui/imgui.zig");
const Flux = @import("Flux.zig");
const Self = @This();

ctx: imgui.Context,
demo: bool = false,
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

  if (self.demo)
    c.igShowDemoWindow(&self.demo);
}

// ---

fn menu(self: *Self, flux: *Flux) void {
  const node_closed = c.ImGuiTreeNodeFlags_SpanAvailWidth;
  const node_open = node_closed | c.ImGuiTreeNodeFlags_DefaultOpen;

  c.igSetNextWindowPos(.{ .x = 16, .y = 16 }, c.ImGuiCond_FirstUseEver, .{ .x = 0, .y = 0 });
  _ = c.igBegin("Menu", null, c.ImGuiWindowFlags_AlwaysAutoResize);
  defer c.igEnd();

  c.igPushItemWidth(128);
  defer c.igPopItemWidth();

  if (c.igTreeNodeEx_Str("Simulation", node_open)) {
    const defs = &flux.programs.update.defs;
    _ = c.igSliderFloat("Time scale", &flux.cfg.time_scale, 0.001, 1.0, null, 0);
    _ = c.igSliderFloat("Space scale", &flux.cfg.space_scale, 0.001, 1.0, null, 0);
    _ = c.igSliderFloat("Air resistance", &flux.cfg.air_resistance, 0.0, 1.0, null, 0);
    _ = c.igSliderFloat("Flux power", &flux.cfg.flux_power, 0.0, 1.0, null, 0);
    _ = c.igSliderFloat("Flux turbulence", &flux.cfg.flux_turbulence, 0.0, 1.0, null, 0);
    _ = c.igCheckbox("Walls collision", &defs.WALLS_COLLISION);
    c.igTreePop();
  }

  if (c.igTreeNodeEx_Str("Rendering", node_open)) {
    const defs = &flux.programs.render.defs;
    const colorspaces = [_][*:0]const u8{ "HSL", "Smooth HSL", "CIELAB", "CIELUV", "CAM16", "Jzazbz", "Oklab" };
    const cs = colorspaces[@intCast(usize, defs.COLORSPACE)];
    _ = c.igSliderInt("Color space", &defs.COLORSPACE, 0, 6, cs, 0);
    _ = c.igCheckbox("Render as lines", &defs.RENDER_AS_LINES);
    if (defs.RENDER_AS_LINES) {
      _ = c.igCheckbox("Dynamic line brightness", &defs.DYNAMIC_LINE_BRIGHTNESS);
    }
    else {
      _ = c.igCheckbox("Fancy point rendering", &defs.FANCY_POINT_RENDERING);
      if (defs.FANCY_POINT_RENDERING)
        _ = c.igSliderFloat("Point scale", &flux.cfg.point_scale, 1.0, 10.0, null, 0);
    }
    _ = c.igSliderFloat("Smooth spawn", &flux.cfg.smooth_spawn, 0.0, 1.0, "%.2fs", 0);
    _ = c.igSliderFloat("Feedback mix", &flux.cfg.feedback, 0.0, 1.0, null, 0);
    c.igTreePop();
  }

  if (c.igTreeNodeEx_Str("Post-processing", node_open)) {
    _ = c.igSliderFloat("Brightness", &flux.cfg.brightness, 0.0, 10.0, null, 0);
    _ = c.igSliderFloat("Bloom mix", &flux.cfg.bloom, 0.0, 1.0, null, 0);
    _ = c.igCheckbox("ACES filmic tone mapping", &flux.programs.postprocess.defs.ACES);
    c.igTreePop();
  }

  if (c.igTreeNodeEx_Str("Performance", node_open)) {
    _ = c.igSliderInt2("Simulation size", &flux.cfg.simulation_size, 1, 2048, null, 0);
    _ = c.igSliderInt("Steps per frame", &flux.cfg.steps_per_frame, 1, 10, null, 0);
    _ = c.igSliderInt("Bloom levels", &flux.cfg.bloom_levels, 1, 10, null, 0);
    _ = c.igSliderFloat("Bloom scale", &flux.programs.bloom_blur.defs.SIGMA, 1.0, 5.0, null, 0);
    _ = c.igCheckbox("Vertical synchronization", &flux.cfg.vsync);
    c.igTreePop();
  }

  if (c.igTreeNodeEx_Str("Metrics", node_open)) {
    imgui.plot("%.1f fps", imgui.io().Framerate, &self.fps);
    imgui.plot("%.1f ms/frame", 1e3 * imgui.io().DeltaTime, &self.dt);
    if (c.igBeginTable("table", 3, c.ImGuiTableFlags_SizingStretchSame, .{ .x = 0, .y = 0 }, 0)) {
      const per_step = flux.cfg.simulation_size[0] * flux.cfg.simulation_size[1];
      const per_frame = per_step * flux.cfg.steps_per_frame;
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

  if (c.igTreeNodeEx_Str("Misc.", node_open)) {
    if (c.igButton("Defaults", .{ .x = 0, .y = 0 }))
      flux.defaults();
    c.igSameLine(0, -1);
    if (c.igButton("Fullscreen", .{ .x = 0, .y = 0 }))
      flux.window.fullscreen();
    c.igSameLine(0, -1);
    _ = c.igCheckbox("Demo window", &self.demo);
    c.igTreePop();
  }

  if (c.igTreeNodeEx_Str("Debug", node_closed)) {
    if (c.igBeginTabBar("tabs", 0)) {
      if (c.igBeginTabItem("Rendering", null, 0)) {
        _ = c.igCheckbox("Point edge linearstep", &flux.programs.render.defs.POINT_EDGE_LINEARSTEP);
        c.igEndTabItem();
      }
      if (c.igBeginTabItem("Post-processing", null, 0)) {
        _ = c.igCheckbox("Use fast ACES approximation", &flux.programs.postprocess.defs.ACES_FAST);
        _ = c.igCheckbox("sRGB OEFT", &flux.programs.postprocess.defs.SRGB_OETF);
        _ = c.igCheckbox("Dithering", &flux.programs.postprocess.defs.DITHER);
        c.igEndTabItem();
      }
      if (c.igBeginTabItem("Bloom", null, 0)) {
        _ = c.igSliderInt("MIP Level", &flux.cfg.bloom_level, 0, flux.cfg.bloom_levels - 1, null, 0);
        _ = c.igSliderInt("MIP Texture", &flux.cfg.bloom_texture, 0, 1, null, 0);
        _ = c.igSliderInt("Downscale mode", &flux.programs.bloom_down.defs.MODE, 0, 3, null, 0);
        _ = c.igSliderFloat("Kernel scale", &flux.programs.bloom_blur.defs.KERNEL_SCALE, 1.0, 5.0, null, 0);
        _ = c.igCheckbox("Bilinear optimization", &flux.programs.bloom_blur.defs.BILINEAR_OPTIMIZATION);
        c.igEndTabItem();
      }
      c.igEndTabBar();
    }
    c.igTreePop();
  }
}
