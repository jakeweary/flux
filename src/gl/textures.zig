const c = @import("../c.zig");
const gl = @import("gl.zig");
const std = @import("std");

const KeyValue = std.meta.Tuple(&.{ c.GLenum, c.GLint });

pub fn init(ids: []c.GLuint, fmt: c.GLenum, w: c.GLint, h: c.GLint) void {
  c.glCreateTextures(c.GL_TEXTURE_2D, @intCast(c.GLsizei, ids.len), ids.ptr);
  for (ids) |id|
    c.glTextureStorage2D(id, 1, fmt, w, h);
}

pub fn deinit(ids: []const c.GLuint) void {
  c.glDeleteTextures(@intCast(c.GLsizei, ids.len), ids.ptr);
}

pub fn resize(ids: []c.GLuint, w: c.GLint, h: c.GLint, params: []const KeyValue) void {
  var fmt: c.GLint = undefined;
  c.glGetTextureLevelParameteriv(ids[0], 0, c.GL_TEXTURE_INTERNAL_FORMAT, &fmt);

  deinit(ids);
  init(ids, @intCast(c.GLenum, fmt), w, h);
  setParams(ids, params);
}

pub fn resizeIfChanged(ids: []c.GLuint, w: c.GLint, h: c.GLint, params: []const KeyValue) bool {
  var curr_w: c.GLint = undefined;
  var curr_h: c.GLint = undefined;
  c.glGetTextureLevelParameteriv(ids[0], 0, c.GL_TEXTURE_WIDTH, &curr_w);
  c.glGetTextureLevelParameteriv(ids[0], 0, c.GL_TEXTURE_HEIGHT, &curr_h);

  const changed = curr_w != w or curr_h != h;
  if (changed) {
    gl.log.debug("resizing {} textures from {}x{} to {}x{}", .{ ids.len, curr_w, curr_h, w, h });
    resize(ids, w, h, params);
  }
  return changed;
}

pub fn setParams(ids: []const c.GLuint, params: []const KeyValue) void {
  for (ids) |id|
    for (params) |kv|
      c.glTextureParameteri(id, kv[0], kv[1]);
}

pub fn swap(pair: *[2]c.GLuint) void {
  std.mem.swap(c.GLuint, &pair[0], &pair[1]);
}
