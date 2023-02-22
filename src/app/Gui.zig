const c = @import("../c.zig");
const std = @import("std");
const imgui = @import("../imgui/imgui.zig");
const App = @import("App.zig");
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

pub fn update(self: *Self, app: *App) void {
  imgui.newFrame();
  self.menu(app);

  if (self.demo)
    c.igShowDemoWindow(&self.demo);
}

// ---

fn menu(self: *Self, app: *App) void {
  const node_closed = c.ImGuiTreeNodeFlags_SpanAvailWidth;
  const node_open = node_closed | c.ImGuiTreeNodeFlags_DefaultOpen;

  c.igSetNextWindowPos(.{ .x = 16, .y = 16 }, c.ImGuiCond_FirstUseEver, .{ .x = 0, .y = 0 });
  _ = c.igBegin("Menu", null, c.ImGuiWindowFlags_AlwaysAutoResize);
  defer c.igEnd();

  c.igPushItemWidth(128);
  defer c.igPopItemWidth();

  if (c.igTreeNodeEx_Str("Simulation", node_open)) {
    const defs = &app.programs.update.defs;
    const respawn_modes = [_][*:0]const u8{ "Same place", "Random place", "Screen edges" };
    const respawn_mode = respawn_modes[@intCast(usize, defs.RESPAWN_MODE)];
    _ = c.igSliderFloat("Time scale", &app.cfg.time_scale, 0.001, 1.0, null, 0);
    _ = c.igSliderFloat("Space scale", &app.cfg.space_scale, 0.001, 1.0, null, 0);
    _ = c.igSliderFloat("Air resistance", &app.cfg.air_resistance, 0.0, 1.0, null, 0);
    _ = c.igSliderFloat("Flux power", &app.cfg.flux_power, 0.0, 1.0, null, 0);
    _ = c.igSliderFloat("Flux turbulence", &app.cfg.flux_turbulence, 0.0, 1.0, null, 0);
    _ = c.igSliderInt("Respawn mode", &defs.RESPAWN_MODE, 0, respawn_modes.len - 1, respawn_mode, 0);
    _ = c.igCheckbox("Walls collision", &defs.WALLS_COLLISION);
    c.igTreePop();
  }

  if (c.igTreeNodeEx_Str("Rendering", node_open)) {
    const defs = &app.programs.render.defs;
    const color_spaces = [_][*:0]const u8{ "HSL", "Smooth HSL", "CIELAB", "CIELUV", "CAM16", "Jzazbz", "Oklab" };
    const color_space = color_spaces[@intCast(usize, defs.COLORSPACE)];
    _ = c.igSliderInt("Color space", &defs.COLORSPACE, 0, color_spaces.len - 1, color_space, 0);
    _ = c.igCheckbox("Render as lines", &defs.RENDER_AS_LINES);
    if (defs.RENDER_AS_LINES) {
      _ = c.igCheckbox("Dynamic line brightness", &defs.DYNAMIC_LINE_BRIGHTNESS);
    }
    else {
      _ = c.igCheckbox("Fancy point rendering", &defs.FANCY_POINT_RENDERING);
      if (defs.FANCY_POINT_RENDERING)
        _ = c.igSliderFloat("Point scale", &app.cfg.point_scale, 1.0, 10.0, null, 0);
    }
    _ = c.igSliderFloat("Smooth spawn", &app.cfg.smooth_spawn, 0.0, 1.0, "%.2fs", 0);
    _ = c.igSliderFloat("Feedback mix", &app.cfg.feedback, 0.0, 1.0, null, 0);
    c.igTreePop();
  }

  if (c.igTreeNodeEx_Str("Post-processing", node_open)) {
    _ = c.igSliderFloat("Brightness", &app.cfg.brightness, 0.0, 10.0, null, 0);
    _ = c.igSliderFloat("Bloom mix", &app.cfg.bloom, 0.0, 1.0, null, 0);
    _ = c.igCheckbox("ACES filmic tone mapping", &app.programs.postprocess.defs.ACES);
    c.igTreePop();
  }

  if (c.igTreeNodeEx_Str("Performance", node_open)) {
    _ = c.igSliderInt2("Simulation size", &app.cfg.simulation_size, 1, 2048, null, 0);
    _ = c.igSliderInt("Steps per frame", &app.cfg.steps_per_frame, 1, 10, null, 0);
    _ = c.igSliderInt("Bloom levels", &app.cfg.bloom_levels, 1, 10, null, 0);
    _ = c.igSliderFloat("Bloom scale", &app.programs.bloom_blur.defs.SIGMA, 1.0, 5.0, null, 0);
    _ = c.igCheckbox("Vertical synchronization", &app.cfg.vsync);
    c.igTreePop();
  }

  if (c.igTreeNodeEx_Str("Metrics", node_open)) {
    imgui.plot("%.1f fps", imgui.io().Framerate, &self.fps);
    imgui.plot("%.1f ms/frame", 1e3 * imgui.io().DeltaTime, &self.dt);
    if (c.igBeginTable("table", 3, c.ImGuiTableFlags_NoHostExtendX, .{ .x = 0, .y = 0 }, 0)) {
      const per_step = app.cfg.simulation_size[0] * app.cfg.simulation_size[1];
      const per_frame = per_step * app.cfg.steps_per_frame;
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
      app.defaults();
    c.igSameLine(0, -1);
    if (c.igButton("Fullscreen", .{ .x = 0, .y = 0 }))
      app.window.fullscreen();
    if (@import("builtin").mode == .Debug) {
      c.igSameLine(0, -1);
      _ = c.igCheckbox("Demo window", &self.demo);
    }
    c.igTreePop();
  }

  if (c.igTreeNodeEx_Str("Debug", node_closed)) {
    if (c.igBeginTabBar("tabs", 0)) {
      if (c.igBeginTabItem("Noise", null, 0)) {
        if (c.igTreeNodeEx_Str("Noise rotation matrix", node_open)) {
          const flags = c.ImGuiTableFlags_Borders | c.ImGuiTableFlags_NoHostExtendX;
          if (c.igBeginTable("table", 3, flags, .{ .x = 0, .y = 0 }, 0)) {
            for (@ptrCast(*[9]c.GLfloat, &app.cfg.noise_rotation)) |value| {
              _ = c.igTableNextColumn();
              c.igText("%8.5f", value);
            }
            c.igEndTable();
          }
          if (c.igButton("Randomize", .{ .x = 0, .y = 0 }))
            app.randomizeNoiseRotation();
          c.igTreePop();
        }
        c.igEndTabItem();
      }
      if (c.igBeginTabItem("Rendering", null, 0)) {
        _ = c.igSliderInt("Line rendering mode", &app.programs.render.defs.LINE_RENDERING_MODE, 0, 2, null, 0);
        _ = c.igCheckbox("Point edge linearstep", &app.programs.render.defs.POINT_EDGE_LINEARSTEP);
        c.igEndTabItem();
      }
      if (c.igBeginTabItem("Post-processing", null, 0)) {
        _ = c.igCheckbox("Use fast ACES approximation", &app.programs.postprocess.defs.ACES_FAST);
        _ = c.igCheckbox("sRGB OEFT", &app.programs.postprocess.defs.SRGB_OETF);
        _ = c.igCheckbox("Dithering", &app.programs.postprocess.defs.DITHER);
        c.igEndTabItem();
      }
      if (c.igBeginTabItem("Bloom", null, 0)) {
        _ = c.igSliderInt("MIP Level", &app.cfg.bloom_level, 0, app.cfg.bloom_levels - 1, null, 0);
        _ = c.igSliderInt("MIP Texture", &app.cfg.bloom_texture, 0, 1, null, 0);
        _ = c.igSliderInt("Downscale mode", &app.programs.bloom_down.defs.MODE, 0, 3, null, 0);
        _ = c.igSliderFloat("Kernel scale", &app.programs.bloom_blur.defs.KERNEL_SCALE, 1.0, 5.0, null, 0);
        _ = c.igCheckbox("Bilinear optimization", &app.programs.bloom_blur.defs.BILINEAR_OPTIMIZATION);
        c.igEndTabItem();
      }
      c.igEndTabBar();
    }
    c.igTreePop();
  }
}
