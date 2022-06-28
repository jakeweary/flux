const std = @import("std");
const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const cfg = @import("config.zig");
const Programs = @import("Programs.zig");
const Textures = @import("Textures.zig");
const Self = @This();

window: *c.GLFWwindow,
width: c_int,
height: c_int,

programs: Programs,
textures: Textures,

fbo: c.GLuint = undefined,
vao: c.GLuint = undefined,

pub fn init(window: *c.GLFWwindow) !Self {
  var width: c_int = undefined;
  var height: c_int = undefined;
  c.glfwGetWindowSize(window, &width, &height);

  var self = Self{
    .window = window,
    .width = width,
    .height = height,
    .programs = try Programs.init(),
    .textures = Textures.init(width, height),
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

  self.programs.deinit();
  self.textures.deinit();
}

pub fn run(self: *Self) !void {
  const time_start = try std.time.Instant.now();
  var time_prev = time_start;
  var frame: usize = 0;

  self.seed();

  while (c.glfwWindowShouldClose(self.window) != c.GLFW_TRUE) : (frame += 1) {
    defer c.glfwPollEvents();
    defer c.glfwSwapBuffers(self.window);

    const time_now = try std.time.Instant.now();
    defer time_prev = time_now;

    const dt = 1e-9 * @intToFloat(f32, time_now.since(time_prev));
    const t = 1e-9 * @intToFloat(f32, time_now.since(time_start));

    var step: usize = cfg.STEPS;
    while (!@subWithOverflow(usize, step, 1, &step)) {
      const local_dt = dt / cfg.STEPS;
      const local_t = t - local_dt * @intToFloat(f32, step);

      self.update(local_t, local_dt);
      self.render();
      self.feedback();
    }

    self.postprocess();
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

  c.glViewport(0, 0, cfg.TEXTURE_SIZE, cfg.TEXTURE_SIZE);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}

fn update(self: *Self, t: f32, dt: f32) void {
  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  self.programs.update.use();
  self.programs.update.bind("uT", t);
  self.programs.update.bind("uDT", dt);
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

  c.glViewport(0, 0, cfg.TEXTURE_SIZE, cfg.TEXTURE_SIZE);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

  gl.swapTextures(self.textures.particleAge());
  gl.swapTextures(self.textures.particlePosition());
  gl.swapTextures(self.textures.particleVelocity());
}

fn render(self: *Self) void {
  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  c.glEnable(c.GL_BLEND);
  c.glBlendFunc(c.GL_ONE, c.GL_ONE);
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
  c.glDrawArrays(c.GL_POINTS, 0, cfg.PARTICLE_COUNT);
}

fn feedback(self: *Self) void {
  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  self.programs.feedback.use();
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
  self.programs.postprocess.bindTexture("tRendered", 0, self.textures.feedback()[0]);

  c.glViewport(0, 0, self.width, self.height);
  c.glClear(c.GL_COLOR_BUFFER_BIT);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}
