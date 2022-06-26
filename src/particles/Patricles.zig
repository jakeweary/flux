const std = @import("std");
const c = @import("../c.zig");
const util = @import("../util.zig");
const gl = @import("../gl/gl.zig");
const stb = @import("../stb/stb.zig");
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
  c.glDeleteFramebuffers(1, &self.fbo);
  c.glDeleteVertexArrays(1, &self.vao);

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

    const frame_start = try std.time.Instant.now();
    const time_now = frame_start;
    defer time_prev = time_now;

    const t = 1e-9 * @intToFloat(f32, time_now.since(time_start));
    const dt = 1e-9 * @intToFloat(f32, time_now.since(time_prev));

    var width: c_int = undefined;
    var height: c_int = undefined;
    c.glfwGetWindowSize(window, &width, &height);

    if (width != 0 and height != 0) {
      self.update(t, dt);
      self.render(width, height);
      self.postprocess(width, height);
    }
  }
}

fn seed(self: *Self) void {
  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  self.programs.seed.use();

  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, self.textures.particle_size(), 0);
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT1, self.textures.particle_velocity()[0], 0);
  c.glDrawBuffers(2, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0, c.GL_COLOR_ATTACHMENT1 });

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
  self.programs.update.bindTexture("tPosition", 1, self.textures.particle_position()[0]);
  self.programs.update.bindTexture("tVelocity", 2, self.textures.particle_velocity()[0]);

  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, self.textures.particle_position()[1], 0);
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT1, self.textures.particle_velocity()[1], 0);
  c.glDrawBuffers(2, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0, c.GL_COLOR_ATTACHMENT1 });

  c.glViewport(0, 0, cfg.TEXTURE_SIZE, cfg.TEXTURE_SIZE);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

  gl.swapTextures(self.textures.particle_position());
  gl.swapTextures(self.textures.particle_velocity());
}

fn render(self: *Self, width: c_int, height: c_int) void {
  c.glBindTexture(c.GL_TEXTURE_2D, self.textures.postprocess());
  c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGB32F, width, height, 0, c.GL_RGB, c.GL_FLOAT, null);
  defer c.glBindTexture(c.GL_TEXTURE_2D, 0);

  c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.fbo);
  defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

  c.glEnable(c.GL_BLEND);
  c.glBlendFunc(c.GL_ONE, c.GL_ONE);
  defer c.glDisable(c.GL_BLEND);

  self.programs.render.use();
  self.programs.render.bindTexture("tSize", 0, self.textures.particle_size());
  self.programs.render.bindTexture("tPosition", 1, self.textures.particle_position()[0]);

  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT0, self.textures.postprocess(), 0);
  c.glNamedFramebufferTexture(self.fbo, c.GL_COLOR_ATTACHMENT1, 0, 0);
  c.glNamedFramebufferDrawBuffers(self.fbo, 1, &[_]c.GLuint{ c.GL_COLOR_ATTACHMENT0 });

  c.glViewport(0, 0, width, height);
  c.glClear(c.GL_COLOR_BUFFER_BIT);
  c.glDrawArrays(c.GL_POINTS, 0, cfg.COUNT);
}

fn postprocess(self: *Self, width: c_int, height: c_int) void {
  c.glEnable(c.GL_FRAMEBUFFER_SRGB);
  defer c.glDisable(c.GL_FRAMEBUFFER_SRGB);

  self.programs.postprocess.use();
  self.programs.postprocess.bindTexture("tPostprocess", 0, self.textures.postprocess());

  c.glViewport(0, 0, width, height);
  c.glClear(c.GL_COLOR_BUFFER_BIT);
  c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
}
