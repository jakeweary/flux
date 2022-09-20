const c = @import("../c.zig");
const gl = @import("gl.zig");
const std = @import("std");
const Self = @This();

const KeyValue = std.meta.Tuple(&.{ c.GLenum, c.GLuint });

fbo: c.GLuint,
kvs: []const KeyValue,

pub fn attach(fbo: c.GLuint, attachments: []const KeyValue) Self {
  c.glBindFramebuffer(c.GL_FRAMEBUFFER, fbo);
  var buf: [32]c.GLenum = undefined;
  for (attachments) |kv, i| {
    buf[i] = kv[0];
    c.glNamedFramebufferTexture(fbo, kv[0], kv[1], 0);
  }
  c.glNamedFramebufferDrawBuffers(fbo, @intCast(c.GLsizei, attachments.len), &buf);
  return .{ .fbo = fbo, .kvs = attachments };
}

pub fn detach(self: *const Self) void {
  for (self.kvs) |kv|
    c.glNamedFramebufferTexture(self.fbo, kv[0], 0, 0);
  c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);
}
