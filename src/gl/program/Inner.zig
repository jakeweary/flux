const c = @import("../../c.zig");
const gl = @import("../gl.zig");
const std = @import("std");
const Builder = @import("Builder.zig");
const Self = @This();

const Texture = std.meta.Tuple(&.{ [*:0]const c.GLchar, c.GLuint });

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

pub fn attribute(self: *const Self, name: [*:0]const c.GLchar) c.GLuint {
  return @intCast(c.GLuint, c.glGetAttribLocation(self.id, name));
}

pub fn uniform(self: *const Self, name: [*:0]const c.GLchar) c.GLint {
  return c.glGetUniformLocation(self.id, name);
}

pub fn use(self: *const Self) void {
  c.glUseProgram(self.id);
}

pub fn bindTexture(self: *const Self, name: [*:0]const c.GLchar, unit: c.GLuint, id: c.GLuint) void {
  c.glBindTextureUnit(unit, id);
  c.glUniform1i(c.glGetUniformLocation(self.id, name), @intCast(c.GLint, unit));
}

pub fn bindTextures(self: *const Self, textures: []const Texture) void {
  for (textures) |t, i|
    self.bindTexture(t[0], @intCast(c.GLuint, i), t[1]);
}

// here goes my attempt to cover (almost) all of `glUniform{1|2|3|4}{f|i|ui}[v]`
pub fn bind(self: *const Self, name: [*:0]const c.GLchar, value: anytype) void {
  const loc = self.uniform(name);
  switch (@typeInfo(@TypeOf(value))) {
    .ComptimeFloat, .Float => c.glUniform1f(loc, @floatCast(c.GLfloat, value)),
    .ComptimeInt, .Int => c.glUniform1i(loc, @intCast(c.GLint, value)),
    .Bool => c.glUniform1i(loc, @boolToInt(value)),
    .Pointer => |ptr| {
      const T = switch (ptr.size) {
        .Slice => ptr.child,
        .One => std.meta.Child(ptr.child),
        else => @compileError("unimplemented")
      };
      const vec = switch (@typeInfo(T)) {
        .Array => |info| info,
        .Vector => |info| info,
        else => @typeInfo([1]T).Array
      };
      const kind = switch (vec.child) {
        c.GLfloat => "f",
        c.GLint => "i",
        c.GLuint => "ui",
        else => @compileError("unimplemented")
      };
      const method = comptime std.fmt.comptimePrint("glUniform{}{s}v", .{ vec.len, kind });
      @field(c, method)(loc, @intCast(c_int, value.len), @ptrCast(*const vec.child, value));
    },
    else => @compileError("unimplemented")
  }
}