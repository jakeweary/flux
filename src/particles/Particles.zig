const std = @import("std");
const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const glfw = @import("../glfw/glfw.zig");
const Gui = @import("Gui.zig");
const Programs = @import("Programs.zig");
const Textures = @import("Textures.zig");
const Self = @This();

window: *const glfw.Window,
width: c_int = 0,
height: c_int = 0,

programs: Programs,
textures: Textures,
gui: Gui,

fbo: c.GLuint = undefined,
vao: c.GLuint = undefined,

cfg: @TypeOf(DEFAULTS) = DEFAULTS,

const DEFAULTS: struct {
  bounce_from_walls: bool = false,
  air_drag: f32 = 0.1,
  wind_power: f32 = 5.0,
  wind_frequency: f32 = 0.5,
  wind_turbulence: f32 = 0.05,
  render_feedback: f32 = 0.9,
  render_opacity: f32 = 0.1,
  steps_per_frame: c_int = 4,
  simulation_size: [2]c_int = .{ 256, 256 },
} = .{};

pub fn init(window: *const glfw.Window) !Self {
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
  self.cfg = DEFAULTS;
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
  gl.resizeTextures(self.textures.rendering(), w, h);
}

pub fn run(self: *Self) !void {
  const time_start = try std.time.Instant.now();
  var time_prev = time_start;
  var frame: usize = 0;

  while (c.glfwWindowShouldClose(self.window.ptr) == c.GLFW_FALSE) : (frame += 1) {
    const ss = self.cfg.simulation_size;
    if (gl.resizeTexturesIfNeeded(self.textures.simulation(), ss[0], ss[1]))
      self.seed();

    self.resize();
    self.gui.update(self);

    const time_now = try std.time.Instant.now();
    defer time_prev = time_now;

    const t = 1e-9 * @intToFloat(f32, time_now.since(time_start));
    const dt = 1e-9 * @intToFloat(f32, time_now.since(time_prev));
    const step_dt = dt / @intToFloat(f32, self.cfg.steps_per_frame);

    var step = self.cfg.steps_per_frame;
    while (step != 0) : (step -= 1) {
      const step_t = t - step_dt * @intToFloat(f32, step);
      self.update(step_t, step_dt);
      self.render();
      self.feedback();
    }

    self.postprocess();
    self.gui.render();

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

fn update(self: *Self, t: f32, dt: f32) void {
  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  self.programs.update.use();
  self.programs.update.bind("uT", t);
  self.programs.update.bind("uDT", dt);
  self.programs.update.bind("uBounceFromWalls", self.cfg.bounce_from_walls);
  self.programs.update.bind("uAirDrag", self.cfg.air_drag);
  self.programs.update.bind("uWindPower", self.cfg.wind_power);
  self.programs.update.bind("uWindFrequency", self.cfg.wind_frequency);
  self.programs.update.bind("uWindTurbulence", self.cfg.wind_turbulence);
  self.programs.update.bind("uViewport", &[_][2]c.GLint{.{ self.width, self.height }});
  self.programs.update.bindTexture("tSize", 0, self.textures.particleSize());
  self.programs.update.bindTexture("tAge", 1, self.textures.particleAge()[0]);
  self.programs.update.bindTexture("tPosition", 2, self.textures.particlePosition()[0]);
  self.programs.update.bindTexture("tVelocity", 3, self.textures.particleVelocity()[0]);

  c.glDrawBuffers(3, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0, c.GL_COLOR_ATTACHMENT1, c.GL_COLOR_ATTACHMENT2 });
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, self.textures.particleAge()[1], 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT1, self.textures.particlePosition()[1], 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT1, 0, 0);
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT2, self.textures.particleVelocity()[1], 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT2, 0, 0);

  c.glViewport(0, 0, self.cfg.simulation_size[0], self.cfg.simulation_size[1]);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

  gl.swapTextures(self.textures.particleAge());
  gl.swapTextures(self.textures.particlePosition());
  gl.swapTextures(self.textures.particleVelocity());
}

fn render(self: *Self) void {
  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  c.glBlendFunc(c.GL_ONE, c.GL_ONE);
  c.glEnable(c.GL_BLEND);
  defer c.glDisable(c.GL_BLEND);

  self.programs.render.use();
  self.programs.render.bindTexture("tSize", 0, self.textures.particleSize());
  self.programs.render.bindTexture("tColor", 1, self.textures.particleColor());
  self.programs.render.bindTexture("tAge", 2, self.textures.particleAge()[0]);
  self.programs.render.bindTexture("tPosition", 3, self.textures.particlePosition()[0]);

  c.glNamedFramebufferDrawBuffers(self.fbo, 1, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0 });
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, self.textures.rendered(), 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);

  c.glViewport(0, 0, self.width, self.height);
  c.glClear(c.GL_COLOR_BUFFER_BIT);
  c.glDrawArrays(c.GL_POINTS, 0, self.cfg.simulation_size[0] * self.cfg.simulation_size[1]);
}

fn feedback(self: *Self) void {
  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  self.programs.feedback.use();
  self.programs.feedback.bind("uFeedback", self.cfg.render_feedback);
  self.programs.feedback.bindTexture("tRendered", 0, self.textures.rendered());
  self.programs.feedback.bindTexture("tFeedback", 1, self.textures.feedback()[0]);

  c.glNamedFramebufferDrawBuffers(self.fbo, 1, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0 });
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, self.textures.feedback()[1], 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);

  c.glViewport(0, 0, self.width, self.height);
  c.glClear(c.GL_COLOR_BUFFER_BIT);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

  gl.swapTextures(self.textures.feedback());
}

fn postprocess(self: *Self) void {
  c.glEnable(c.GL_FRAMEBUFFER_SRGB);
  defer c.glDisable(c.GL_FRAMEBUFFER_SRGB);

  self.programs.postprocess.use();
  self.programs.postprocess.bind("uOpacity", self.cfg.render_opacity);
  self.programs.postprocess.bindTexture("tRendered", 0, self.textures.feedback()[0]);

  c.glViewport(0, 0, self.width, self.height);
  c.glClear(c.GL_COLOR_BUFFER_BIT);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}
