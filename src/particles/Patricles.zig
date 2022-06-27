const std = @import("std");
const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const cfg = @import("config.zig");
const Programs = @import("Programs.zig");
const Textures = @import("Textures.zig");
const Self = @This();

fbo: c.GLuint = undefined,
vao: c.GLuint = undefined,
programs: Programs,
textures: Textures,

pub fn init() !Self {
  var self = Self{
    .programs = try Programs.init(),
    .textures = Textures.init(),
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

pub fn run(self: *Self, window: *c.GLFWwindow) !void {
  const time_start = try std.time.Instant.now();
  var time_prev = time_start;
  var frame: usize = 0;

  self.seed();

  while (c.glfwWindowShouldClose(window) != c.GLFW_TRUE) : (frame += 1) {
    defer c.glfwPollEvents();
    defer c.glfwSwapBuffers(window);

    var width: c_int = undefined;
    var height: c_int = undefined;
    c.glfwGetWindowSize(window, &width, &height);

    if (width == 0 or height == 0)
      continue;

    const time_now = try std.time.Instant.now();
    defer time_prev = time_now;

    const t = 1e-9 * @intToFloat(f32, time_now.since(time_start));
    const dt = 1e-9 * @intToFloat(f32, time_now.since(time_prev));

    const steps = 16;
    var step: usize = steps;
    while (!@subWithOverflow(usize, step, 1, &step)) {
      const step_dt = dt / steps;
      const step_t = t - step_dt * @intToFloat(f32, step);

      self.update(step_t, step_dt);
      self.render(width, height);
      self.feedback(width, height);
    }

    self.postprocess(width, height);
  }
}

// ---

fn seed(self: *Self) void {
  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  self.programs.seed.use();

  c.glDrawBuffers(4, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0, c.GL_COLOR_ATTACHMENT1, c.GL_COLOR_ATTACHMENT2, c.GL_COLOR_ATTACHMENT3 });
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, self.textures.particle_size(), 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT1, self.textures.particle_color(), 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT1, 0, 0);
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT2, self.textures.particle_age()[0], 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT2, 0, 0);
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT3, self.textures.particle_velocity()[0], 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT3, 0, 0);

  c.glViewport(0, 0, cfg.TEXTURE_SIZE, cfg.TEXTURE_SIZE);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}

fn update(self: *Self, t: f32, dt: f32) void {
  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  self.programs.update.use();
  self.programs.update.bind("uT", t);
  self.programs.update.bind("uDT", dt);
  self.programs.update.bindTexture("tSize", 0, self.textures.particle_size());
  self.programs.update.bindTexture("tAge", 1, self.textures.particle_age()[0]);
  self.programs.update.bindTexture("tPosition", 2, self.textures.particle_position()[0]);
  self.programs.update.bindTexture("tVelocity", 3, self.textures.particle_velocity()[0]);

  c.glDrawBuffers(3, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0, c.GL_COLOR_ATTACHMENT1, c.GL_COLOR_ATTACHMENT2 });
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, self.textures.particle_age()[1], 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT1, self.textures.particle_position()[1], 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT1, 0, 0);
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT2, self.textures.particle_velocity()[1], 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT2, 0, 0);

  c.glViewport(0, 0, cfg.TEXTURE_SIZE, cfg.TEXTURE_SIZE);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

  gl.swapTextures(self.textures.particle_age());
  gl.swapTextures(self.textures.particle_position());
  gl.swapTextures(self.textures.particle_velocity());
}

fn render(self: *Self, width: c_int, height: c_int) void {
  c.glBindTexture(c.GL_TEXTURE_2D, self.textures.rendered());
  c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGB32F, width, height, 0, c.GL_RGB, c.GL_FLOAT, null);
  defer c.glBindTexture(c.GL_TEXTURE_2D, 0);

  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  c.glEnable(c.GL_BLEND);
  c.glBlendFunc(c.GL_ONE, c.GL_ONE);
  defer c.glDisable(c.GL_BLEND);

  self.programs.render.use();
  self.programs.render.bindTexture("tSize", 0, self.textures.particle_size());
  self.programs.render.bindTexture("tColor", 1, self.textures.particle_color());
  self.programs.render.bindTexture("tAge", 2, self.textures.particle_age()[0]);
  self.programs.render.bindTexture("tPosition", 3, self.textures.particle_position()[0]);

  c.glNamedFramebufferDrawBuffers(self.fbo, 1, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0 });
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, self.textures.rendered(), 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);

  c.glViewport(0, 0, width, height);
  c.glClear(c.GL_COLOR_BUFFER_BIT);
  c.glDrawArrays(c.GL_POINTS, 0, cfg.COUNT);
}

fn feedback(self: *Self, width: c_int, height: c_int) void {
  c.glBindTexture(c.GL_TEXTURE_2D, self.textures.feedback()[1]);
  c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGB32F, width, height, 0, c.GL_RGB, c.GL_FLOAT, null);
  defer c.glBindTexture(c.GL_TEXTURE_2D, 0);

  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  self.programs.feedback.use();
  self.programs.feedback.bindTexture("tRendered", 0, self.textures.rendered());
  self.programs.feedback.bindTexture("tFeedback", 1, self.textures.feedback()[0]);

  c.glNamedFramebufferDrawBuffers(self.fbo, 1, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0 });
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, self.textures.feedback()[1], 0);
  defer c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, 0, 0);

  c.glViewport(0, 0, width, height);
  c.glClear(c.GL_COLOR_BUFFER_BIT);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

  gl.swapTextures(self.textures.feedback());
}

fn postprocess(self: *Self, width: c_int, height: c_int) void {
  c.glEnable(c.GL_FRAMEBUFFER_SRGB);
  defer c.glDisable(c.GL_FRAMEBUFFER_SRGB);

  self.programs.postprocess.use();
  self.programs.postprocess.bindTexture("tRendered", 0, self.textures.feedback()[0]);

  c.glViewport(0, 0, width, height);
  c.glClear(c.GL_COLOR_BUFFER_BIT);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}
