const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const Self = @This();

textures: [11]c.GLuint = undefined,

pub fn init() Self {
  var self = Self{};
  gl.textures.init(self.rendering(), c.GL_RGB16F, 1, 1);
  gl.textures.init(self.simulation(), c.GL_RGB32F, 1, 1);
  return self;
}

pub fn deinit(self: *const Self) void {
  gl.textures.deinit(&self.textures);
}

// ---

pub inline fn rendering(self: *Self) *[3]c.GLuint {
  return self.textures[0..3];
}

pub inline fn rendered(self: *Self) c.GLuint {
  return self.textures[0];
}

pub inline fn feedback(self: *Self) *[2]c.GLuint {
  return self.textures[1..3];
}

// ---

pub inline fn simulation(self: *Self) *[8]c.GLuint {
  return self.textures[3..];
}

pub inline fn particleSize(self: *Self) c.GLuint {
  return self.textures[3];
}

pub inline fn particleColor(self: *Self) c.GLuint {
  return self.textures[4];
}

pub inline fn particleAge(self: *Self) *[2]c.GLuint {
  return self.textures[5..7];
}

pub inline fn particlePosition(self: *Self) *[2]c.GLuint {
  return self.textures[7..9];
}

pub inline fn particleVelocity(self: *Self) *[2]c.GLuint {
  return self.textures[9..11];
}
