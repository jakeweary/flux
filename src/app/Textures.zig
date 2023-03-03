const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const stb = @import("../stb/stb.zig");
const Self = @This();

bluenoise: c.GLuint = undefined,
msaa: c.GLuint = undefined,
simulation: [6]c.GLuint = undefined,
rendering: [3]c.GLuint = undefined,
bloom: [2]c.GLuint = undefined,

pub fn init() !Self {
  var self = Self{};

  const bn_png = @embedFile("../../deps/assets/bluenoise/128/LDR_RGB1_0.png");
  const bn = try stb.Image.fromMemory(bn_png);
  const bn_w = @intCast(c.GLsizei, bn.width);
  const bn_h = @intCast(c.GLsizei, bn.height);
  defer bn.deinit();

  c.glCreateTextures(c.GL_TEXTURE_2D, 1, &self.bluenoise);
  c.glTextureStorage2D(self.bluenoise, 1, c.GL_RGB8, bn_w, bn_h);
  c.glTextureSubImage2D(self.bluenoise, 0, 0, 0, bn_w, bn_h, c.GL_RGB, c.GL_UNSIGNED_BYTE, bn.data.ptr);

  c.glCreateTextures(c.GL_TEXTURE_2D_MULTISAMPLE, 1, &self.msaa);
  c.glCreateTextures(c.GL_TEXTURE_2D, self.simulation.len, &self.simulation);
  c.glCreateTextures(c.GL_TEXTURE_2D, self.rendering.len, &self.rendering);
  c.glCreateTextures(c.GL_TEXTURE_2D, self.bloom.len, &self.bloom);

  return self;
}

pub fn deinit(self: *const Self) void {
  c.glDeleteTextures(1, &self.bluenoise);
  c.glDeleteTextures(1, &self.msaa);
  c.glDeleteTextures(self.simulation.len, &self.simulation);
  c.glDeleteTextures(self.rendering.len, &self.rendering);
  c.glDeleteTextures(self.bloom.len, &self.bloom);
}

// ---

pub inline fn rendered(self: *Self) c.GLuint {
  return self.rendering[0];
}

pub inline fn feedback(self: *Self) *[2]c.GLuint {
  return self.rendering[1..3];
}

// ---

pub inline fn age(self: *Self) *[2]c.GLuint {
  return self.simulation[0..2];
}

pub inline fn position(self: *Self) *[2]c.GLuint {
  return self.simulation[2..4];
}

pub inline fn velocity(self: *Self) *[2]c.GLuint {
  return self.simulation[4..6];
}

// ---

pub fn resizeMSAA(self: *Self, w: c.GLsizei, h: c.GLsizei, samples: c.GLsizei) bool {
  const changed = samples > 1 and blk: {
    var info: struct { w: c.GLsizei, h: c.GLsizei, samples: c.GLsizei } = undefined;
    c.glGetTextureLevelParameteriv(self.msaa, 0, c.GL_TEXTURE_WIDTH, &info.w);
    c.glGetTextureLevelParameteriv(self.msaa, 0, c.GL_TEXTURE_HEIGHT, &info.h);
    c.glGetTextureLevelParameteriv(self.msaa, 0, c.GL_TEXTURE_SAMPLES, &info.samples);
    break :blk info.w != w or info.h != h or info.samples != samples;
  };
  if (changed) {
    c.glDeleteTextures(1, &self.msaa);
    c.glCreateTextures(c.GL_TEXTURE_2D_MULTISAMPLE, 1, &self.msaa);
    c.glTextureStorage2DMultisample(self.msaa, samples, c.GL_RGB32F, w, h, c.GL_FALSE);
  }
  return changed;
}

pub fn resizeSimulation(self: *Self, w: c.GLsizei, h: c.GLsizei) bool {
  const changed = blk: {
    var info: struct { w: c.GLsizei, h: c.GLsizei } = undefined;
    c.glGetTextureLevelParameteriv(self.simulation[0], 0, c.GL_TEXTURE_WIDTH, &info.w);
    c.glGetTextureLevelParameteriv(self.simulation[0], 0, c.GL_TEXTURE_HEIGHT, &info.h);
    break :blk info.w != w or info.h != h;
  };
  if (changed) {
    c.glDeleteTextures(self.simulation.len, &self.simulation);
    c.glCreateTextures(c.GL_TEXTURE_2D, self.simulation.len, &self.simulation);
    for (self.age())      |id| c.glTextureStorage2D(id, 1, c.GL_R32F,  w, h);
    for (self.position()) |id| c.glTextureStorage2D(id, 1, c.GL_RG32F, w, h);
    for (self.velocity()) |id| c.glTextureStorage2D(id, 1, c.GL_RG32F, w, h);
  }
  return changed;
}

pub fn resizeRendering(self: *Self, w: c.GLsizei, h: c.GLsizei) bool {
  const changed = blk: {
    var info: struct { w: c.GLsizei, h: c.GLsizei } = undefined;
    c.glGetTextureLevelParameteriv(self.rendering[0], 0, c.GL_TEXTURE_WIDTH, &info.w);
    c.glGetTextureLevelParameteriv(self.rendering[0], 0, c.GL_TEXTURE_HEIGHT, &info.h);
    break :blk info.w != w or info.h != h;
  };
  if (changed) {
    c.glDeleteTextures(self.rendering.len, &self.rendering);
    c.glCreateTextures(c.GL_TEXTURE_2D, self.rendering.len, &self.rendering);
    for (self.rendering) |id| {
      c.glTextureStorage2D(id, 1, c.GL_RGB32F, w, h);
      c.glTextureParameteri(id, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
      c.glTextureParameteri(id, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);
      c.glTextureParameteri(id, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
      c.glTextureParameteri(id, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
    }
  }
  return changed;
}

pub fn resizeBloom(self: *Self, w: c.GLsizei, h: c.GLsizei, mips: c.GLsizei) bool {
  const changed = blk: {
    var info: struct { w: c.GLsizei, h: c.GLsizei, mips: c.GLsizei } = undefined;
    c.glGetTextureLevelParameteriv(self.bloom[0], 0, c.GL_TEXTURE_WIDTH, &info.w);
    c.glGetTextureLevelParameteriv(self.bloom[0], 0, c.GL_TEXTURE_HEIGHT, &info.h);
    c.glGetTextureParameteriv(self.bloom[0], c.GL_TEXTURE_IMMUTABLE_LEVELS, &info.mips);
    break :blk info.w != w or info.h != h or info.mips != mips;
  };
  if (changed) {
    c.glDeleteTextures(self.bloom.len, &self.bloom);
    c.glCreateTextures(c.GL_TEXTURE_2D, self.bloom.len, &self.bloom);
    for (self.bloom) |id| {
      c.glTextureStorage2D(id, mips, c.GL_RGB32F, w, h);
      c.glTextureParameteri(id, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
      c.glTextureParameteri(id, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);
      c.glTextureParameteri(id, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR_MIPMAP_NEAREST);
      c.glTextureParameteri(id, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
    }
  }
  return changed;
}
