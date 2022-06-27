const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const cfg = @import("config.zig");
const Self = @This();

textures: [9]c.GLuint = undefined,

pub fn init() Self {
  var self = Self{};
  c.glGenTextures(self.textures.len, &self.textures);

  defer c.glBindTexture(c.GL_TEXTURE_2D, 0);

  for (self.textures) |id| {
    c.glBindTexture(c.GL_TEXTURE_2D, id);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0,
      c.GL_RGB32F, cfg.TEXTURE_SIZE, cfg.TEXTURE_SIZE, 0,
      c.GL_RGB, c.GL_FLOAT, null);
    gl.textureFilterNearest();
  }

  c.glBindTexture(c.GL_TEXTURE_2D, self.particle_size());
  c.glTexImage2D(c.GL_TEXTURE_2D, 0,
    c.GL_R32F, cfg.TEXTURE_SIZE, cfg.TEXTURE_SIZE, 0,
    c.GL_RED, c.GL_FLOAT, null);

  for ([_][]const c.GLuint{ self.particle_position(), self.particle_velocity() }) |ids| {
    for (ids) |id| {
      c.glBindTexture(c.GL_TEXTURE_2D, id);
      c.glTexImage2D(c.GL_TEXTURE_2D, 0,
        c.GL_RG32F, cfg.TEXTURE_SIZE, cfg.TEXTURE_SIZE, 0,
        c.GL_RG, c.GL_FLOAT, null);
    }
  }

  return self;
}

pub fn deinit(self: *const Self) void {
  c.glDeleteTextures(self.textures.len, &self.textures);
}

pub fn particle_size(self: *Self) c.GLuint {
  return self.textures[0];
}

pub fn particle_color(self: *Self) c.GLuint {
  return self.textures[1];
}

pub fn particle_position(self: *Self) []c.GLuint {
  return self.textures[2..4];
}

pub fn particle_velocity(self: *Self) []c.GLuint {
  return self.textures[4..6];
}

pub fn feedback(self: *Self) []c.GLuint {
  return self.textures[6..8];
}

pub fn rendered(self: *Self) c.GLuint {
  return self.textures[8];
}
