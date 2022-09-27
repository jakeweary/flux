const std = @import("std");
const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const glfw = @import("../glfw/glfw.zig");
const util = @import("util.zig");
const Config = @import("Config.zig");
const Gui = @import("Gui.zig");
const Programs = @import("Programs.zig");
const Textures = @import("Textures.zig");
const Self = @This();

const log = std.log.scoped(.Flux);

window: *glfw.Window,
width: c_int = 0,
height: c_int = 0,

cfg: Config = .{},
gui: Gui,
programs: Programs,
textures: Textures,

fbo: c.GLuint = undefined,
vao: c.GLuint = undefined,

pub fn init(window: *glfw.Window) !Self {
  var self = Self{
    .window = window,
    .programs = try Programs.init(),
    .textures = try Textures.init(),
    .gui = Gui.init(window.ptr),
  };

  c.glGenFramebuffers(1, &self.fbo);
  c.glGenVertexArrays(1, &self.vao);
  c.glBindVertexArray(self.vao);

  c.glDisable(c.GL_DITHER);
  c.glEnable(c.GL_VERTEX_PROGRAM_POINT_SIZE);

  return self;
}

pub fn deinit(self: *const Self) void {
  c.glBindVertexArray(0);
  c.glDeleteVertexArrays(1, &self.vao);
  c.glDeleteFramebuffers(1, &self.fbo);

  self.gui.deinit();
  self.textures.deinit();
  self.programs.deinit();
}

pub fn defaults(self: *Self) void {
  self.cfg = .{};
  self.programs.defaults();
}

pub fn resize(self: *Self) void {
  if (c.glfwGetWindowAttrib(self.window.ptr, c.GLFW_ICONIFIED) == c.GLFW_TRUE)
    return;

  var w: c_int = undefined;
  var h: c_int = undefined;
  c.glfwGetWindowSize(self.window.ptr, &w, &h);
  if (self.width == w and self.height == h)
    return;

  self.width = w;
  self.height = h;
  gl.textures.resize(&self.textures.rendering, 1, w, h, &.{
    .{ c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE },
    .{ c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE },
  });
}

pub fn run(self: *Self) !void {
  var timer = try std.time.Timer.start();
  var t: f32 = 0;

  while (c.glfwWindowShouldClose(self.window.ptr) == c.GLFW_FALSE) {
    log.debug("--- new frame ---", .{});

    const ss = self.cfg.simulation_size;
    if (gl.textures.resizeIfChanged(&self.textures.simulation, 1, ss[0], ss[1], &.{}))
      self.seed();

    self.resize();
    self.gui.update(self);
    try self.programs.reinit();

    const dt = 1e-9 * self.cfg.time_scale * @intToFloat(f32, timer.lap());
    const step_dt = dt / @intToFloat(f32, self.cfg.steps_per_frame);
    t += dt;

    var step = self.cfg.steps_per_frame;
    while (step != 0) : (step -= 1) {
      const step_t = t - step_dt * @intToFloat(f32, step);
      self.update(step_t, step_dt);
      self.render(step_t, step_dt);
      self.feedback();
    }

    self.bloom();
    self.postprocess();
    self.gui.render();

    c.glfwSwapInterval(@boolToInt(self.cfg.vsync));
    c.glfwSwapBuffers(self.window.ptr);
    c.glfwPollEvents();
  }
}

// ---

fn seed(self: *Self) void {
  log.debug("step: seed", .{});

  _ = self.programs.seed.use();

  const fbo = gl.Framebuffer.attach(self.fbo, &.{
    .{ c.GL_COLOR_ATTACHMENT0, self.textures.position()[0], 0 },
    .{ c.GL_COLOR_ATTACHMENT1, self.textures.velocity()[0], 0 },
  });
  defer fbo.detach();

  c.glViewport(0, 0, self.cfg.simulation_size[0], self.cfg.simulation_size[1]);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}

fn update(self: *Self, t: f32, dt: f32) void {
  log.debug("step: update", .{});

  const program = self.programs.update.use();
  program.uniforms(.{
    .uT = t,
    .uDT = dt,
    .uSpaceScale = self.cfg.space_scale * 2,
    .uAirResistance = util.logarithmic(5, 1 - self.cfg.air_resistance),
    .uFluxPower = self.cfg.flux_power * 100,
    .uFluxTurbulence = self.cfg.flux_turbulence,
    .uViewport = &[_][2]c.GLint{.{ self.width, self.height }},
  });
  program.textures(.{
    .tAge = self.textures.age()[0],
    .tPosition = self.textures.position()[0],
    .tVelocity = self.textures.velocity()[0],
  });

  const fbo = gl.Framebuffer.attach(self.fbo, &.{
    .{ c.GL_COLOR_ATTACHMENT0, self.textures.age()[1], 0 },
    .{ c.GL_COLOR_ATTACHMENT1, self.textures.position()[1], 0 },
    .{ c.GL_COLOR_ATTACHMENT2, self.textures.velocity()[1], 0 },
  });
  defer fbo.detach();

  c.glViewport(0, 0, self.cfg.simulation_size[0], self.cfg.simulation_size[1]);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

  gl.textures.swap(self.textures.age());
  gl.textures.swap(self.textures.position());
  gl.textures.swap(self.textures.velocity());
}

fn render(self: *Self, t: f32, dt: f32) void {
  log.debug("step: render", .{});

  c.glBlendFunc(c.GL_ONE, c.GL_ONE);
  c.glEnable(c.GL_BLEND);
  defer c.glDisable(c.GL_BLEND);

  const program = self.programs.render.use();
  program.uniforms(.{
    .uT = t,
    .uDT = dt,
    .uPointScale = self.cfg.point_scale,
    .uSmoothSpawn = self.cfg.smooth_spawn,
    .uViewport = &[_][2]c.GLint{.{ self.width, self.height }},
  });
  program.textures(.{
    .tAge = self.textures.age()[0],
    .tPosition = self.textures.position()[0],
    .tVelocity = self.textures.velocity()[0],
  });

  const fbo = gl.Framebuffer.attach(self.fbo, &.{
    .{ c.GL_COLOR_ATTACHMENT0, self.textures.rendered(), 0 },
  });
  defer fbo.detach();

  c.glViewport(0, 0, self.width, self.height);
  c.glClear(c.GL_COLOR_BUFFER_BIT);

  if (self.programs.render.defs.RENDER_AS_LINES)
    c.glDrawArrays(c.GL_LINES, 0, self.cfg.simulation_size[0] * self.cfg.simulation_size[1] * 2)
  else
    c.glDrawArrays(c.GL_POINTS, 0, self.cfg.simulation_size[0] * self.cfg.simulation_size[1]);
}

fn feedback(self: *Self) void {
  log.debug("step: feedback", .{});

  const program = self.programs.feedback.use();
  program.uniforms(.{
    .uMix = 1 - util.logarithmic(5, 1 - self.cfg.feedback),
  });
  program.textures(.{
    .tRendered = self.textures.rendered(),
    .tFeedback = self.textures.feedback()[0],
  });

  const fbo = gl.Framebuffer.attach(self.fbo, &.{
    .{ c.GL_COLOR_ATTACHMENT0, self.textures.feedback()[1], 0 },
  });
  defer fbo.detach();

  c.glViewport(0, 0, self.width, self.height);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

  gl.textures.swap(self.textures.feedback());
}

fn postprocess(self: *Self) void {
  log.debug("step: postprocess", .{});

  const program = self.programs.postprocess.use();
  program.uniforms(.{
    .uBrightness = self.cfg.brightness,
    .uBloomMix = self.cfg.bloom,
    .uBloomLvl = self.cfg.bloom_level,
  });
  program.textures(.{
    .tRendered = self.textures.feedback()[0],
    .tBloom = self.textures.bloom[@intCast(usize, self.cfg.bloom_texture)],
    .tBlueNoise = self.textures.bluenoise,
  });

  c.glViewport(0, 0, self.width, self.height);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}

fn bloom(self: *Self) void {
  log.debug("step: bloom", .{});

  if (self.cfg.bloom == 0)
    return log.debug("skipping", .{});

  const ids = &self.textures.bloom;
  _ = gl.textures.resizeIfChanged(ids, self.cfg.bloom_levels, self.width, self.height, &.{
    .{ c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE },
    .{ c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE },
    .{ c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR_MIPMAP_NEAREST },
    .{ c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR },
  });

  log.debug("substep: downscale and blur", .{});
  var i: c.GLint = 0;
  while (i < self.cfg.bloom_levels) : (i += 1) {
    var size: struct { w: c.GLsizei, h: c.GLsizei } = undefined;
    c.glGetTextureLevelParameteriv(ids[0], i, c.GL_TEXTURE_WIDTH, &size.w);
    c.glGetTextureLevelParameteriv(ids[0], i, c.GL_TEXTURE_HEIGHT, &size.h);
    log.debug("{}x{}", .{ size.w, size.h });

    const src = switch (i) {
      0 => self.textures.feedback()[0],
      else => blk: {
        self.bloomDown(ids[1], ids[1], i, size.w, size.h);
        break :blk ids[1];
      },
    };

    self.bloomBlur(src, ids[0], i, size.w, size.h, .{ 1, 0 }); // horizontal pass
    self.bloomBlur(ids[0], ids[1], i, size.w, size.h, .{ 0, 1 }); // vertical pass
  }

  log.debug("substep: upscale and merge", .{});
  const j_first = self.cfg.bloom_levels - 2;
  var j = j_first;
  while (j >= 0) : (j -= 1) {
    var size: struct { w: c.GLsizei, h: c.GLsizei } = undefined;
    c.glGetTextureLevelParameteriv(ids[0], j, c.GL_TEXTURE_WIDTH, &size.w);
    c.glGetTextureLevelParameteriv(ids[0], j, c.GL_TEXTURE_HEIGHT, &size.h);
    log.debug("{}x{}", .{ size.w, size.h });

    const prev = if (j == j_first) ids[1] else ids[0];
    self.bloomUp(prev, ids[1], ids[0], j, size.w, size.h);
  }
}

fn bloomBlur(self: *Self, src: c.GLuint, dst: c.GLuint, lvl: c.GLint, w: c.GLsizei, h: c.GLsizei, dir: [2]f32) void {
  const program = self.programs.bloom_blur.use();
  program.uniforms(.{ .uSrcLvl = lvl, .uDirection = &[_][2]f32{ dir } });
  program.textures(.{ .tSrc = src });

  const fbo = gl.Framebuffer.attach(self.fbo, &.{
    .{ c.GL_COLOR_ATTACHMENT0, dst, lvl },
  });
  defer fbo.detach();

  c.glViewport(0, 0, w, h);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}

fn bloomDown(self: *Self, src: c.GLuint, dst: c.GLuint, lvl: c.GLint, w: c.GLsizei, h: c.GLsizei) void {
  const program = self.programs.bloom_down.use();
  program.uniforms(.{ .uSrcLvl = lvl - 1 });
  program.textures(.{ .tSrc = src });

  const fbo = gl.Framebuffer.attach(self.fbo, &.{
    .{ c.GL_COLOR_ATTACHMENT0, dst, lvl },
  });
  defer fbo.detach();

  c.glViewport(0, 0, w, h);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}

fn bloomUp(self: *Self, prev: c.GLuint, curr: c.GLuint, dst: c.GLuint, lvl: c.GLint, w: c.GLsizei, h: c.GLsizei) void {
  const program = self.programs.bloom_up.use();
  program.uniforms(.{ .uCurrLvl = lvl });
  program.textures(.{ .tCurr = curr, .tPrev = prev });

  const fbo = gl.Framebuffer.attach(self.fbo, &.{
    .{ c.GL_COLOR_ATTACHMENT0, dst, lvl },
  });
  defer fbo.detach();

  c.glViewport(0, 0, w, h);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}
