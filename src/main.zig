const c = @import("c.zig");
const std = @import("std");
const util = @import("util.zig");
const gl = @import("gl/gl.zig");
const stb = @import("stb/stb.zig");

pub const log_level = std.log.Level.debug;
pub const allocator = std.heap.c_allocator;

pub fn main() !void {
  // const size = .{ .width = 960, .height = 540 };
  const size = .{ .width = 720, .height = 720 };
  // const size = .{ .width = 1280, .height = 720 };

  _ = c.glfwSetErrorCallback(gl.callbacks.onError);

  if (c.glfwInit() == c.GLFW_FALSE)
    return error.GLFW_InitError;
  defer c.glfwTerminate();

  c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, gl.major);
  c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, gl.minor);
  c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
  c.glfwWindowHint(c.GLFW_OPENGL_DEBUG_CONTEXT, c.GLFW_TRUE);
  const window = c.glfwCreateWindow(size.width, size.height, "", null, null)
    orelse return error.GLFW_CreateWindowError;
  defer c.glfwDestroyWindow(window);

  _ = c.glfwSetWindowSizeCallback(window, gl.callbacks.onWindowSize);
  _ = c.glfwSetKeyCallback(window, gl.callbacks.onKey);
  c.glfwMakeContextCurrent(window);
  c.glfwSwapInterval(0);
  _ = c.gladLoadGL(c.glfwGetProcAddress);

  gl.debug.enableDebugMessages();

  // ---

  // const lib_sRGB = @embedFile("glsl/lib/sRGB.glsl");
  const lib_aces = @embedFile("glsl/lib/aces.glsl");
  const lib_colormaps = @embedFile("glsl/lib/colormaps.glsl");
  const lib_simplex3d = @embedFile("glsl/lib/simplex3d.glsl");

  const prog_feedback = try blk: {
    const vs = @embedFile("glsl/pass/feedback/vertex.glsl");
    const fs = @embedFile("glsl/pass/feedback/fragment.glsl");
    break :blk gl.Program.init(&.{ vs }, &.{ lib_simplex3d, fs });
  };
  defer prog_feedback.deinit();

  const prog_render = try blk: {
    const vs = @embedFile("glsl/pass/render/vertex.glsl");
    const fs = @embedFile("glsl/pass/render/fragment.glsl");
    break :blk gl.Program.init(&.{ vs }, &.{ lib_aces, lib_colormaps, fs });
  };
  defer prog_render.deinit();

  // ---

  var textures: [3]c.GLuint = undefined;
  c.glGenTextures(textures.len, &textures);
  defer c.glDeleteTextures(textures.len, &textures);

  const tx_feedback = textures[0..2];
  const tx_noise = textures[2];

  {
    defer c.glBindTexture(c.GL_TEXTURE_2D, 0);

    for (tx_feedback) |id| {
      c.glBindTexture(c.GL_TEXTURE_2D, id);
      c.glTexImage2D(c.GL_TEXTURE_2D, 0,
        c.GL_RGBA32F, size.width, size.height, 0,
        c.GL_RGBA, c.GL_FLOAT, null);
      gl.textureFilterLinear();
      gl.textureClampToEdges();
    }

    {
      const png = @embedFile("../deps/bluenoise/128/LDR_RGB1_0.png");
      const noise = try stb.Image.fromMemory(png);
      defer noise.deinit();

      c.glBindTexture(c.GL_TEXTURE_2D, tx_noise);
      c.glTexImage2D(c.GL_TEXTURE_2D, 0,
        c.GL_RGBA8, @intCast(c.GLint, noise.width), @intCast(c.GLint, noise.height), 0,
        c.GL_RGBA, c.GL_UNSIGNED_BYTE, noise.data.ptr);
      gl.textureFilterNearest();
    }
  }

  // ---

  var fbo: c.GLuint = undefined;
  c.glGenFramebuffers(1, &fbo);
  defer c.glDeleteFramebuffers(1, &fbo);

  var vao: c.GLuint = undefined;
  c.glGenVertexArrays(1, &vao);
  defer c.glDeleteVertexArrays(1, &vao);

  c.glBindVertexArray(vao);
  defer c.glBindVertexArray(0);

  c.glDisable(c.GL_DITHER);

  // ---

  const time_start = try std.time.Instant.now();
  var time_prev = time_start;
  var frame: usize = 0;

  while (c.glfwWindowShouldClose(window) != c.GLFW_TRUE) : (frame += 1) {
    defer c.glfwPollEvents();
    defer c.glfwSwapBuffers(window);
    defer c.glUseProgram(0);

    const frame_start = try std.time.Instant.now();
    const time_now = frame_start;
    defer time_prev = time_now;

    const t = 1e-9 * @intToFloat(f32, time_now.since(time_start));
    const dt = 1e-9 * @intToFloat(f32, time_now.since(time_prev));

    {
      defer std.mem.swap(c.GLuint, &tx_feedback[0], &tx_feedback[1]);

      c.glBindFramebuffer(c.GL_FRAMEBUFFER, fbo);
      c.glNamedFramebufferTexture(fbo, c.GL_COLOR_ATTACHMENT0, tx_feedback[1], 0);

      prog_feedback.use();
      prog_feedback.bindTexture("tFeedback", 0, tx_feedback[0]);
      prog_feedback.bind("uT", t);
      prog_feedback.bind("uDT", dt);

      c.glViewport(0, 0, size.width, size.height);
      c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
    }

    {
      c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

      // c.glEnable(c.GL_FRAMEBUFFER_SRGB);
      // defer c.glDisable(c.GL_FRAMEBUFFER_SRGB);

      prog_render.use();
      prog_render.bindTexture("tFeedback", 0, tx_feedback[0]);

      c.glViewport(0, 0, size.width, size.height);
      c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
    }
  }
}
