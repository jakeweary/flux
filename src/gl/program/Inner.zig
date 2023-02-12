const c = @import("../../c.zig");
const gl = @import("../gl.zig");
const std = @import("std");
const Builder = @import("Builder.zig");
const Self = @This();

id: c.GLuint,

pub fn init(vert: []const [*:0]const c.GLchar, frag: []const [*:0]const c.GLchar) !Self {
  const b = Builder.init();
  try b.attach(c.GL_VERTEX_SHADER, vert);
  try b.attach(c.GL_FRAGMENT_SHADER, frag);
  return .{ .id = try b.link() };
}

pub fn deinit(self: *const Self) void {
  c.glDeleteProgram(self.id);
}

pub fn use(self: *const Self) void {
  c.glUseProgram(self.id);
}

pub fn textures(self: *const Self, arg: anytype) void {
  inline for (@typeInfo(@TypeOf(arg)).Struct.fields) |f, i|
    self.texture(f.name ++ "", @intCast(c.GLuint, i), @field(arg, f.name));
}

pub fn uniforms(self: *const Self, arg: anytype) void {
  inline for (@typeInfo(@TypeOf(arg)).Struct.fields) |f|
    self.uniform(f.name ++ "", @field(arg, f.name));
}

pub fn texture(self: *const Self, name: [*:0]const c.GLchar, unit: c.GLuint, id: c.GLuint) void {
  c.glBindTextureUnit(unit, id);
  c.glUniform1i(c.glGetUniformLocation(self.id, name), @intCast(c.GLint, unit));
}

pub fn uniform(self: *const Self, name: [*:0]const c.GLchar, value: anytype) void {
  gl.uniform(c.glGetUniformLocation(self.id, name), value);
}
