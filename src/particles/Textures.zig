const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const Self = @This();

simulation: [8]c.GLuint = undefined,
rendering: [13]c.GLuint = undefined,
bloom: [8][2]c.GLuint = undefined,
empty: c.GLuint = undefined,

pub fn init() Self {
  var self = Self{};
  gl.textures.init(&self.simulation, c.GL_RGB32F, 1, 1);
  gl.textures.init(&self.rendering, c.GL_RGB16F, 1, 1);
  gl.textures.init(@ptrCast(*[8 * 2]c.GLuint, &self.bloom), c.GL_RGB16F, 1, 1);
  gl.textures.init(@ptrCast(*[1]c.GLuint, &self.empty), c.GL_R8, 1, 1);
  return self;
}

pub fn deinit(self: *const Self) void {
  gl.textures.deinit(&self.simulation);
  gl.textures.deinit(&self.rendering);
  gl.textures.deinit(@ptrCast(*[8 * 2]c.GLuint, &self.bloom));
  gl.textures.deinit(@ptrCast(*[1]c.GLuint, &self.empty));
}

// ---

pub inline fn rendered(self: *Self) c.GLuint {
  return self.rendering[0];
}

pub inline fn feedback(self: *Self) *[2]c.GLuint {
  return self.rendering[1..3];
}

// ---

pub inline fn particleSize(self: *Self) c.GLuint {
  return self.simulation[0];
}

pub inline fn particleColor(self: *Self) c.GLuint {
  return self.simulation[1];
}

pub inline fn particleAge(self: *Self) *[2]c.GLuint {
  return self.simulation[2..4];
}

pub inline fn particlePosition(self: *Self) *[2]c.GLuint {
  return self.simulation[4..6];
}

pub inline fn particleVelocity(self: *Self) *[2]c.GLuint {
  return self.simulation[6..8];
}
