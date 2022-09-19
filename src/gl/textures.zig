const c = @import("../c.zig");
const gl = @import("gl.zig");
const std = @import("std");

const KeyAndValue = std.meta.Tuple(&.{ c.GLenum, c.GLint });

pub fn init(ids: []const c.GLuint, fmt: c.GLenum, w: c.GLint, h: c.GLint) void {
  c.glCreateTextures(c.GL_TEXTURE_2D, @intCast(c.GLsizei, ids.len), ids.ptr);
  for (ids) |id|
    c.glTextureStorage2D(id, 1, fmt, w, h);
}

pub fn deinit(ids: []const c.GLuint) void {
  c.glDeleteTextures(@intCast(c.GLsizei, ids.len), ids.ptr);
}

pub fn resize(ids: []const c.GLuint, w: c.GLint, h: c.GLint) void {
  var fmt: c.GLint = undefined;
  c.glGetTextureLevelParameteriv(ids[0], 0, c.GL_TEXTURE_INTERNAL_FORMAT, &fmt);
  deinit(ids);
  init(ids, @intCast(c.GLenum, fmt), w, h);
}

pub fn params(ids: []const c.GLuint, pairs: []const KeyAndValue) void {
  for (ids) |id|
    for (pairs) |pair|
      c.glTextureParameteri(id, pair[0], pair[1]);
}

pub fn resizeIfNeeded(ids: []const c.GLuint, w: c.GLint, h: c.GLint) bool {
  var curr_w: c.GLint = undefined;
  var curr_h: c.GLint = undefined;
  c.glGetTextureLevelParameteriv(ids[0], 0, c.GL_TEXTURE_WIDTH, &curr_w);
  c.glGetTextureLevelParameteriv(ids[0], 0, c.GL_TEXTURE_HEIGHT, &curr_h);

  const changed = curr_w != w or curr_h != h;
  if (changed) {
    gl.log.debug("resizing {} textures from {}x{} to {}x{}", .{ ids.len, curr_w, curr_h, w, h });
    resize(ids, w, h);
  }
  return changed;
}

pub fn swap(ids: *[2]c.GLuint) void {
  std.mem.swap(c.GLuint, &ids[0], &ids[1]);
}
