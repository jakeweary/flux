const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const cfg = @import("config.zig");
const Self = @This();

textures: [11]c.GLuint = undefined,

pub fn init(width: c_int, height: c_int) Self {
  var self = Self{};
  c.glCreateTextures(c.GL_TEXTURE_2D, self.textures.len, &self.textures);

  for (self.textures[0..3]) |id|
    c.glTextureStorage2D(id, 1, c.GL_RGB32F, width, height);

  for (self.textures[3..]) |id|
    c.glTextureStorage2D(id, 1, c.GL_RGB32F, cfg.TEXTURE_SIZE, cfg.TEXTURE_SIZE);

  return self;
}

pub fn deinit(self: *const Self) void {
  c.glDeleteTextures(self.textures.len, &self.textures);
}

// ---

pub fn rendered(self: *Self) c.GLuint {
  return self.textures[0];
}

pub fn feedback(self: *Self) *[2]c.GLuint {
  return self.textures[1..3];
}

// ---

pub fn particleSize(self: *Self) c.GLuint {
  return self.textures[3];
}

pub fn particleColor(self: *Self) c.GLuint {
  return self.textures[4];
}

pub fn particleAge(self: *Self) *[2]c.GLuint {
  return self.textures[5..7];
}

pub fn particlePosition(self: *Self) *[2]c.GLuint {
  return self.textures[7..9];
}

pub fn particleVelocity(self: *Self) *[2]c.GLuint {
  return self.textures[9..11];
}
