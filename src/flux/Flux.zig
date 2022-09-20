const std = @import("std");
const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const glfw = @import("../glfw/glfw.zig");
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
  gl.textures.resize(&self.textures.rendering, w, h, &.{
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
    if (gl.textures.resizeIfNeeded(&self.textures.simulation, ss[0], ss[1], &.{}))
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
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, self.textures.size(), 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT1, self.textures.color(), 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT1, 0, 0);
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT2, self.textures.velocity()[0], 0);
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
  program.bind("uFluxPower", self.cfg.flux_power * 100);
  program.bind("uFluxTurbulence", self.cfg.flux_turbulence);
  program.bind("uViewport", &[_][2]c.GLint{.{ self.width, self.height }});
  program.bindTextures(&.{
    .{ "tSize", self.textures.size() },
    .{ "tAge", self.textures.age()[0] },
    .{ "tPosition", self.textures.position()[0] },
    .{ "tVelocity", self.textures.velocity()[0] },
  });

  c.glDrawBuffers(3, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0, c.GL_COLOR_ATTACHMENT1, c.GL_COLOR_ATTACHMENT2 });
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, self.textures.age()[1], 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT1, self.textures.position()[1], 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT1, 0, 0);
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT2, self.textures.velocity()[1], 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT2, 0, 0);

  c.glViewport(0, 0, self.cfg.simulation_size[0], self.cfg.simulation_size[1]);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

  std.mem.reverse(c.GLuint, self.textures.age());
  std.mem.reverse(c.GLuint, self.textures.position());
  std.mem.reverse(c.GLuint, self.textures.velocity());
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
  program.bind("uSmoothSpawn", self.cfg.smooth_spawn);
  program.bind("uViewport", &[_][2]c.GLint{.{ self.width, self.height }});
  program.bindTextures(&.{
    .{ "tSize", self.textures.size() },
    .{ "tColor", self.textures.color() },
    .{ "tAge", self.textures.age()[0] },
    .{ "tPosition", self.textures.position()[0] },
    .{ "tVelocity", self.textures.velocity()[0] },
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
  program.bind("uMix", 1 - logarithmic(5, 1 - self.cfg.feedback));
  program.bindTextures(&.{
    .{ "tRendered", self.textures.rendered() },
    .{ "tFeedback", self.textures.feedback()[0] },
  });

  c.glNamedFramebufferDrawBuffers(self.fbo, 1, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0 });
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, self.textures.feedback()[1], 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);

  c.glViewport(0, 0, self.width, self.height);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

  std.mem.reverse(c.GLuint, self.textures.feedback());
}

fn postprocess(self: *Self) void {
  log.debug("step: postprocess", .{});

  c.glEnable(c.GL_FRAMEBUFFER_SRGB);
  defer c.glDisable(c.GL_FRAMEBUFFER_SRGB);

  const bi = @intCast(usize, self.cfg.bloom_layer - 1);
  const bj = @intCast(usize, self.cfg.bloom_sublayer - 1);

  const program = self.programs.postprocess.inner;
  program.use();
  program.bind("uBrightness", self.cfg.brightness);
  program.bind("uBloomMix", self.cfg.bloom);
  program.bindTextures(&.{
    .{ "tRendered", self.textures.feedback()[0] },
    .{ "tBloom", self.textures.bloom[bi][bj] },
  });

  c.glViewport(0, 0, self.width, self.height);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}

fn bloom(self: *Self) void {
  log.debug("step: bloom", .{});

  const blur = self.programs.bloom_blur.inner;
  const down = self.programs.bloom_down.inner;
  const up = self.programs.bloom_up.inner;

  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  log.debug("substep: downscale", .{});

  var layers = self.textures.bloom;
  for (layers[0..]) |*pair, i| {
    const sh = @truncate(u5, i);
    const w = self.width >> sh;
    const h = self.height >> sh;
    log.debug("{}x{}", .{ w, h });

    _ = gl.textures.resizeIfNeeded(pair, w, h, &.{
      .{ c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE },
      .{ c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE },
    });

    // downscale (or no-op)

    const src = switch (i) {
      0 => self.textures.feedback()[0],
      else => downscale: {
        down.use();
        down.bindTextures(&.{
          .{ "tSrc", layers[i - 1][1] },
        });

        c.glNamedFramebufferDrawBuffers(self.fbo, 1, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0 });
        c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, pair[1], 0);
        defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);

        c.glViewport(0, 0, w, h);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

        break :downscale pair[1];
      },
    };

    // blur: horizontal pass

    blur.use();
    blur.bind("uDirection", &[_][2]f32{ .{ 1, 0 } });
    blur.bindTextures(&.{
      .{ "tSrc", src },
    });

    c.glNamedFramebufferDrawBuffers(self.fbo, 1, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0 });
    c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, pair[0], 0);
    defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);

    c.glViewport(0, 0, w, h);
    c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

    // blur: vertical pass

    blur.use();
    blur.bind("uDirection", &[_][2]f32{ .{ 0, 1 } });
    blur.bindTextures(&.{
      .{ "tSrc", pair[0] },
    });

    c.glNamedFramebufferDrawBuffers(self.fbo, 1, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0 });
    c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, pair[1], 0);
    defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);

    c.glViewport(0, 0, w, h);
    c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
  }

  log.debug("substep: upscale", .{});

  std.mem.reverse([2]c.GLuint, &layers);
  std.mem.reverse(c.GLuint, &layers[0]);
  for (layers[1..]) |*pair, i| {
    const sh = @truncate(u5, layers.len - i - 2);
    const w = self.width >> sh;
    const h = self.height >> sh;
    log.debug("{}x{}", .{ w, h });

    // upscale + merge

    up.use();
    up.bindTextures(&.{
      .{ "tA", pair[1] },
      .{ "tB", layers[i][0] },
    });

    c.glNamedFramebufferDrawBuffers(self.fbo, 1, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0 });
    c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, pair[0], 0);
    defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);

    c.glViewport(0, 0, w, h);
    c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
  }
}

// ---

inline fn logarithmic(amp: f32, t: f32) f32 {
  return (@exp(t * amp) - 1) / (@exp(amp) - 1);
}
