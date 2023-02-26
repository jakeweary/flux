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

const log = std.log.scoped(.App);

cfg: Config = .{},
window: *glfw.Window,
gui: Gui,
programs: Programs,
textures: Textures,
fbo: c.GLuint = undefined,
vao: c.GLuint = undefined,

pub fn init(window: *glfw.Window) !Self {
  var self = Self{
    .window = window,
    .gui = Gui.init(window.ptr),
    .programs = try Programs.init(),
    .textures = try Textures.init(),
  };

  c.glCreateFramebuffers(1, &self.fbo);
  c.glCreateVertexArrays(1, &self.vao);
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

pub fn resetToDefaults(self: *Self) void {
  self.cfg = .{};
  self.programs.defaults();
}

pub fn randomizeNoiseRotation(self: *Self) void {
  const time_ns = std.time.nanoTimestamp();
  const prng_seed = @truncate(u64, @bitCast(u128, time_ns));
  var prng = std.rand.DefaultPrng.init(prng_seed);
  var rand = prng.random();
  self.cfg.noise_rotation = util.randomRotationMatrix(f32, &rand);
}

pub fn run(self: *Self) !void {
  self.setupCallbacks();

  var timer = try std.time.Timer.start();
  var t: f32 = 0;

  while (c.glfwWindowShouldClose(self.window.ptr) == c.GLFW_FALSE) {
    c.glfwPollEvents();
    if (c.glfwGetWindowAttrib(self.window.ptr, c.GLFW_ICONIFIED) == c.GLFW_TRUE)
      continue;

    log.debug("--- new frame ---", .{});

    const dt = 1e-9 * self.cfg.time_scale * @intToFloat(f32, timer.lap());
    const step_dt = dt / @intToFloat(f32, self.cfg.steps_per_frame);
    t += dt;

    var size: struct { w: c_int, h: c_int } = undefined;
    c.glfwGetFramebufferSize(self.window.ptr, &size.w, &size.h);

    self.gui.update(self);
    try self.programs.reinit();

    _ = gl.textures.resizeIfChanged(&self.textures.rendering, 1, size.w, size.h, &.{
      .{ c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE },
      .{ c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE },
      .{ c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR },
      .{ c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR },
    });

    const ss = self.cfg.simulation_size;
    if (gl.textures.resizeIfChanged(&self.textures.simulation, 1, ss[0], ss[1], &.{}))
      self.seed();

    var step = self.cfg.steps_per_frame;
    while (step != 0) : (step -= 1) {
      const step_t = t - step_dt * @intToFloat(f32, step);
      self.update(step_t, step_dt, size.w, size.h);
      self.render(step_t, step_dt, size.w, size.h);
      self.feedback();
    }

    self.bloom(size.w, size.h);
    self.postprocess(size.w, size.h);
    self.gui.render();

    c.glfwSwapInterval(@boolToInt(self.cfg.vsync));
    c.glfwSwapBuffers(self.window.ptr);
  }
}

// ---

fn setupCallbacks(self: *Self) void {
  const callbacks = struct {
    fn onKey(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
      glfw.windowUserPointerUpcast(Self, window).onKey(key, scancode, action, mods);
      c.ImGui_ImplGlfw_KeyCallback(window, key, scancode, action, mods);
    }
  };

  _ = c.glfwSetKeyCallback(self.window.ptr, callbacks.onKey);
  c.glfwSetWindowUserPointer(self.window.ptr, self);
}

fn onKey(self: *Self, key: c_int, _: c_int, action: c_int, mods: c_int) void {
  if (action != c.GLFW_PRESS)
    return;

  if (key == c.GLFW_KEY_ESCAPE)
    c.glfwSetWindowShouldClose(self.window.ptr, c.GLFW_TRUE);

  if (mods == c.GLFW_MOD_ALT and key == c.GLFW_KEY_ENTER or key == c.GLFW_KEY_F11)
    self.window.fullscreen();
}

// ---

fn seed(self: *Self) void {
  log.debug("step: seed", .{});

  _ = self.programs.seed.use();

  const fbo = gl.Framebuffer.attach(self.fbo, &.{
    .{ self.textures.position()[0], 0 },
    .{ self.textures.velocity()[0], 0 },
  });
  defer fbo.detach();

  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}

fn update(self: *Self, t: f32, dt: f32, w: c_int, h: c_int) void {
  log.debug("step: update", .{});

  const program = self.programs.update.use();
  program.uniforms(.{
    .uT = t,
    .uDT = dt,
    .uSpaceScale = self.cfg.space_scale * 2,
    .uAirResistance = util.logarithmic(5, 1 - self.cfg.air_resistance),
    .uFluxPower = self.cfg.flux_power * 100,
    .uFluxTurbulence = self.cfg.flux_turbulence,
    .uViewport = &[_][2]c.GLint{.{ w, h }},
    .uNoiseRotation = &[_][3][3]c.GLfloat{ self.cfg.noise_rotation },
  });
  program.textures(.{
    .tAge = self.textures.age()[0],
    .tPosition = self.textures.position()[0],
    .tVelocity = self.textures.velocity()[0],
  });

  const fbo = gl.Framebuffer.attach(self.fbo, &.{
    .{ self.textures.age()[1], 0 },
    .{ self.textures.position()[1], 0 },
    .{ self.textures.velocity()[1], 0 },
  });
  defer fbo.detach();

  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

  gl.textures.swap(self.textures.age());
  gl.textures.swap(self.textures.position());
  gl.textures.swap(self.textures.velocity());
}

fn render(self: *Self, t: f32, dt: f32, w: c_int, h: c_int) void {
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
    .uViewport = &[_][2]c.GLint{.{ w, h }},
  });
  program.textures(.{
    .tAge = self.textures.age()[0],
    .tPosition = self.textures.position()[0],
    .tVelocity = self.textures.velocity()[0],
  });

  const fbo = gl.Framebuffer.attach(self.fbo, &.{
    .{ self.textures.rendered(), 0 },
  });
  defer fbo.detach();

  c.glClear(c.GL_COLOR_BUFFER_BIT);

  const count = self.cfg.simulation_size[0] * self.cfg.simulation_size[1];
  if (self.programs.render.defs.RENDER_AS_LINES)
    c.glDrawArrays(c.GL_LINES, 0, count * 2)
  else
    c.glDrawArrays(c.GL_POINTS, 0, count);
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
    .{ self.textures.feedback()[1], 0 },
  });
  defer fbo.detach();

  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

  gl.textures.swap(self.textures.feedback());
}

fn postprocess(self: *Self, w: c_int, h: c_int) void {
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

  c.glViewport(0, 0, w, h);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}

fn bloom(self: *Self, w: c_int, h: c_int) void {
  log.debug("step: bloom", .{});

  if (self.cfg.bloom == 0)
    return log.debug("skipping", .{});

  const ids = &self.textures.bloom;
  _ = gl.textures.resizeIfChanged(ids, self.cfg.bloom_levels, w, h, &.{
    .{ c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE },
    .{ c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE },
    .{ c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR_MIPMAP_NEAREST },
    .{ c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR },
  });

  log.debug("substep: blur and downscale", .{});
  var i: c.GLint = 0;
  while (i < self.cfg.bloom_levels) : (i += 1) {
    const src = if (i == 0) self.textures.feedback()[0] else blk: {
      self.bloomDown(ids[1], ids[1], i);
      break :blk ids[1];
    };
    self.bloomBlur(src, ids[0], i, .{ 1, 0 }); // horizontal pass
    self.bloomBlur(ids[0], ids[1], i, .{ 0, 1 }); // vertical pass
  }

  log.debug("substep: upscale and merge", .{});
  const j_first = self.cfg.bloom_levels - 2;
  var j = j_first;
  while (j >= 0) : (j -= 1) {
    const prev = if (j == j_first) ids[1] else ids[0];
    self.bloomUp(prev, ids[1], ids[0], j);
  }
}

fn bloomBlur(self: *Self, src: c.GLuint, dst: c.GLuint, lvl: c.GLint, dir: [2]f32) void {
  const program = self.programs.bloom_blur.use();
  program.uniforms(.{ .uSrcLvl = lvl, .uDirection = &[_][2]f32{ dir } });
  program.textures(.{ .tSrc = src });

  const fbo = gl.Framebuffer.attach(self.fbo, &.{
    .{ dst, lvl },
  });
  defer fbo.detach();

  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}

fn bloomDown(self: *Self, src: c.GLuint, dst: c.GLuint, lvl: c.GLint) void {
  const program = self.programs.bloom_down.use();
  program.uniforms(.{ .uSrcLvl = lvl - 1 });
  program.textures(.{ .tSrc = src });

  const fbo = gl.Framebuffer.attach(self.fbo, &.{
    .{ dst, lvl },
  });
  defer fbo.detach();

  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}

fn bloomUp(self: *Self, prev: c.GLuint, curr: c.GLuint, dst: c.GLuint, lvl: c.GLint) void {
  const program = self.programs.bloom_up.use();
  program.uniforms(.{ .uCurrLvl = lvl });
  program.textures(.{ .tCurr = curr, .tPrev = prev });

  const fbo = gl.Framebuffer.attach(self.fbo, &.{
    .{ dst, lvl },
  });
  defer fbo.detach();

  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}
