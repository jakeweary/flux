const std = @import("std");
const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const glfw = @import("../glfw/glfw.zig");
const Config = @import("Config.zig");
const Gui = @import("Gui.zig");
const Programs = @import("Programs.zig");
const Textures = @import("Textures.zig");
const Self = @This();

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
  gl.textures.resize(self.textures.rendering(), w, h);
}

pub fn run(self: *Self) !void {
  var timer = try std.time.Timer.start();
  var t: f32 = 0;

  while (c.glfwWindowShouldClose(self.window.ptr) == c.GLFW_FALSE) {
    const ss = self.cfg.simulation_size;
    if (gl.textures.resizeIfNeeded(self.textures.simulation(), ss[0], ss[1]))
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

    self.postprocess();
    self.gui.render();

    c.glfwSwapInterval(@boolToInt(self.cfg.vsync));
    c.glfwSwapBuffers(self.window.ptr);
    c.glfwPollEvents();
  }
}

// ---

fn seed(self: *Self) void {
  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  self.programs.seed.use();

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
  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  self.programs.update.use();
  self.programs.update.bind("uT", t);
  self.programs.update.bind("uDT", dt);
  self.programs.update.bind("uSpaceScale", self.cfg.space_scale * 2);
  self.programs.update.bind("uAirResistance", logarithmic(5, 1 - self.cfg.air_resistance));
  self.programs.update.bind("uWindPower", self.cfg.wind_power * 100);
  self.programs.update.bind("uWindTurbulence", self.cfg.wind_turbulence);
  self.programs.update.bind("uViewport", &[_][2]c.GLint{.{ self.width, self.height }});
  self.programs.update.bindTextures(&.{
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
  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  c.glBlendFunc(c.GL_ONE, c.GL_ONE);
  c.glEnable(c.GL_BLEND);
  defer c.glDisable(c.GL_BLEND);

  self.programs.render.use();
  self.programs.render.bind("uDT", dt);
  self.programs.render.bind("uPointScale", self.cfg.point_scale);
  self.programs.render.bind("uViewport", &[_][2]c.GLint{.{ self.width, self.height }});
  self.programs.render.bindTextures(&.{
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
  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  self.programs.feedback.use();
  self.programs.feedback.bind("uRatio", 1 - logarithmic(5, 1 - self.cfg.feedback_loop));
  self.programs.feedback.bindTextures(&.{
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
  c.glEnable(c.GL_FRAMEBUFFER_SRGB);
  defer c.glDisable(c.GL_FRAMEBUFFER_SRGB);

  self.programs.postprocess.use();
  self.programs.postprocess.bind("uBrightness", self.cfg.brightness);
  self.programs.postprocess.bindTextures(&.{
    .{ "tRendered", self.textures.feedback()[0] },
  });

  c.glViewport(0, 0, self.width, self.height);
  c.glClear(c.GL_COLOR_BUFFER_BIT);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}

// ---

inline fn logarithmic(amp: f32, t: f32) f32 {
  return (@exp(t * amp) - 1) / (@exp(amp) - 1);
}
