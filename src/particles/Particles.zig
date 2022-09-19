const std = @import("std");
const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const glfw = @import("../glfw/glfw.zig");
const Config = @import("Config.zig");
const Gui = @import("Gui.zig");
const Programs = @import("Programs.zig");
const Textures = @import("Textures.zig");
const Self = @This();

const log = std.log.scoped(.Particles);

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
    .textures = Textures.init(),
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
  gl.textures.resize(&self.textures.rendering, w, h);
}

pub fn run(self: *Self) !void {
  var timer = try std.time.Timer.start();
  var t: f32 = 0;

  while (c.glfwWindowShouldClose(self.window.ptr) == c.GLFW_FALSE) {
    log.debug("--- new frame ---", .{});

    const ss = self.cfg.simulation_size;
    if (gl.textures.resizeIfNeeded(&self.textures.simulation, ss[0], ss[1]))
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
      self.update(step_dt, step_t);
      self.render(step_dt);
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

  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  const program = self.programs.seed.inner;
  program.use();

  c.glDrawBuffers(3, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0, c.GL_COLOR_ATTACHMENT1, c.GL_COLOR_ATTACHMENT2 });
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, self.textures.particleSize(), 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT1, self.textures.particleColor(), 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT1, 0, 0);
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT2, self.textures.particleVelocity()[0], 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT2, 0, 0);

  c.glViewport(0, 0, self.cfg.simulation_size[0], self.cfg.simulation_size[1]);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}

fn update(self: *Self, dt: f32, t: f32) void {
  log.debug("step: update", .{});

  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  const program = self.programs.update.inner;
  program.use();
  program.bind("uT", t);
  program.bind("uDT", dt);
  program.bind("uSpaceScale", self.cfg.space_scale * 2);
  program.bind("uAirResistance", logarithmic(5, 1 - self.cfg.air_resistance));
  program.bind("uWindPower", self.cfg.wind_power * 100);
  program.bind("uWindTurbulence", self.cfg.wind_turbulence);
  program.bind("uViewport", &[_][2]c.GLint{.{ self.width, self.height }});
  program.bindTextures(&.{
    .{ "tSize", self.textures.particleSize() },
    .{ "tAge", self.textures.particleAge()[0] },
    .{ "tPosition", self.textures.particlePosition()[0] },
    .{ "tVelocity", self.textures.particleVelocity()[0] },
  });

  c.glDrawBuffers(3, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0, c.GL_COLOR_ATTACHMENT1, c.GL_COLOR_ATTACHMENT2 });
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, self.textures.particleAge()[1], 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT1, self.textures.particlePosition()[1], 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT1, 0, 0);
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT2, self.textures.particleVelocity()[1], 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT2, 0, 0);

  c.glViewport(0, 0, self.cfg.simulation_size[0], self.cfg.simulation_size[1]);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

  gl.textures.swap(self.textures.particleAge());
  gl.textures.swap(self.textures.particlePosition());
  gl.textures.swap(self.textures.particleVelocity());
}

fn render(self: *Self, dt: f32) void {
  log.debug("step: render", .{});

  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  c.glBlendFunc(c.GL_ONE, c.GL_ONE);
  c.glEnable(c.GL_BLEND);
  defer c.glDisable(c.GL_BLEND);

  const program = self.programs.render.inner;
  program.use();
  program.bind("uDT", dt);
  program.bind("uPointScale", self.cfg.point_scale);
  program.bind("uViewport", &[_][2]c.GLint{.{ self.width, self.height }});
  program.bindTextures(&.{
    .{ "tSize", self.textures.particleSize() },
    .{ "tColor", self.textures.particleColor() },
    .{ "tAge", self.textures.particleAge()[0] },
    .{ "tPosition", self.textures.particlePosition()[0] },
    .{ "tVelocity", self.textures.particleVelocity()[0] },
  });

  c.glNamedFramebufferDrawBuffers(self.fbo, 1, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0 });
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, self.textures.rendered(), 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);

  c.glViewport(0, 0, self.width, self.height);
  c.glClear(c.GL_COLOR_BUFFER_BIT);
  if (self.programs.render.defs.RENDER_AS_LINES)
    c.glDrawArrays(c.GL_LINES, 0, self.cfg.simulation_size[0] * self.cfg.simulation_size[1] * 2)
  else
    c.glDrawArrays(c.GL_POINTS, 0, self.cfg.simulation_size[0] * self.cfg.simulation_size[1]);
}

fn feedback(self: *Self) void {
  log.debug("step: feedback", .{});

  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  const program = self.programs.feedback.inner;
  program.use();
  program.bind("uRatio", 1 - logarithmic(5, 1 - self.cfg.feedback_loop));
  program.bindTextures(&.{
    .{ "tRendered", self.textures.rendered() },
    .{ "tFeedback", self.textures.feedback()[0] },
  });

  c.glNamedFramebufferDrawBuffers(self.fbo, 1, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0 });
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, self.textures.feedback()[1], 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);

  c.glViewport(0, 0, self.width, self.height);
  c.glClear(c.GL_COLOR_BUFFER_BIT);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

  gl.textures.swap(self.textures.feedback());
}

fn postprocess(self: *Self) void {
  log.debug("step: postprocess", .{});

  c.glEnable(c.GL_FRAMEBUFFER_SRGB);
  defer c.glDisable(c.GL_FRAMEBUFFER_SRGB);

  const program = self.programs.postprocess.inner;
  program.use();
  program.bind("uBrightness", self.cfg.brightness);
  program.bindTextures(&.{
    .{ "tRendered", self.textures.feedback()[0] },
    .{ "tBloom", self.textures.bloom[0][0] },
  });

  c.glViewport(0, 0, self.width, self.height);
  c.glClear(c.GL_COLOR_BUFFER_BIT);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}

fn bloom(self: *Self) void {
  log.debug("step: bloom", .{});

  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  log.debug("bloom: down", .{});
  const down = self.programs.bloom_down.inner;
  down.use();

  var textures = self.textures.bloom;
  for (&textures) |tx, i| {
    const sh = @truncate(u5, i);
    const w = self.width >> sh;
    const h = self.height >> sh;
    log.debug("{} {}x{} {any}", .{ i, w, h, tx });

    if (gl.textures.resizeIfNeeded(&tx, w, h)) {
      gl.textures.params(&tx, &.{
        .{ c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE },
        .{ c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE },
      });
    }

    const src = switch (i) {
      0 => self.textures.feedback()[0],
      else => textures[i - 1][0],
    };

    down.bind("uMultipleSamples", i != 0);
    down.bindTextures(&.{
      .{ "tSrc", src },
    });

    c.glNamedFramebufferDrawBuffers(self.fbo, 1, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0 });
    c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, tx[0], 0);
    defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);

    c.glViewport(0, 0, w, h);
    c.glClear(c.GL_COLOR_BUFFER_BIT);
    c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
  }

  log.debug("bloom: up", .{});
  const up = self.programs.bloom_up.inner;
  up.use();

  std.mem.reverse([2]c.GLuint, &textures);
  for (&textures) |tx, i| {
    const sh = @truncate(u5, textures.len - i - 1);
    const w = self.width >> sh;
    const h = self.height >> sh;
    log.debug("{} {}x{} {any}", .{ i, w, h, tx });

    // horizontal pass

    up.bind("uDirection", &[_][2]f32{ .{ 1, 0 } });
    up.bindTextures(&.{
      .{ "tSrc", tx[0] },
      .{ "tAdd", self.textures.empty[0] },
    });

    c.glNamedFramebufferDrawBuffers(self.fbo, 1, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0 });
    c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, tx[1], 0);
    defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);

    c.glViewport(0, 0, w, h);
    c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

    // vertical pass + add

    const add = switch (i) {
      0 => self.textures.empty[0],
      else => textures[i - 1][0],
    };

    up.bind("uDirection", &[_][2]f32{ .{ 0, 1 } });
    up.bindTextures(&.{
      .{ "tSrc", tx[1] },
      .{ "tAdd", add },
    });

    c.glNamedFramebufferDrawBuffers(self.fbo, 1, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0 });
    c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, tx[0], 0);
    defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);

    c.glViewport(0, 0, w, h);
    c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
  }
}

// ---

inline fn logarithmic(amp: f32, t: f32) f32 {
  return (@exp(t * amp) - 1) / (@exp(amp) - 1);
}
