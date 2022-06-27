const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const cfg = @import("config.zig");
const Self = @This();

textures: [11]c.GLuint = undefined,

pub fn init() Self {
  var self = Self{};
  c.glGenTextures(self.textures.len, &self.textures);

  for (self.textures) |id| {
    c.glBindTexture(c.GL_TEXTURE_2D, id);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0,
      c.GL_RGB32F, cfg.TEXTURE_SIZE, cfg.TEXTURE_SIZE, 0,
      c.GL_RGB, c.GL_FLOAT, null);
    gl.textureFilterNearest();
  }
  c.glBindTexture(c.GL_TEXTURE_2D, 0);

  return self;
}

pub fn deinit(self: *const Self) void {
  c.glDeleteTextures(self.textures.len, &self.textures);
}

pub fn rendered(self: *Self) c.GLuint {
  return self.textures[0];
}

pub fn feedback(self: *Self) []c.GLuint {
  return self.textures[1..3];
}

pub fn particle_size(self: *Self) c.GLuint {
  return self.textures[3];
}

pub fn particle_color(self: *Self) c.GLuint {
  return self.textures[4];
}

pub fn particle_age(self: *Self) []c.GLuint {
  return self.textures[5..7];
}

pub fn particle_position(self: *Self) []c.GLuint {
  return self.textures[7..9];
}

pub fn particle_velocity(self: *Self) []c.GLuint {
  return self.textures[9..11];
}
