const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const stb = @import("../stb/stb.zig");
const Self = @This();

bluenoise: c.GLuint = undefined,
bloom: [8][2]c.GLuint = undefined,
rendering: [3]c.GLuint = undefined,
simulation: [6]c.GLuint = undefined,

pub fn init() !Self {
  var self = Self{};

  const bn_png = @embedFile("../../deps/assets/bluenoise/128/LDR_RGB1_0.png");
  const bn = try stb.Image.fromMemory(bn_png);
  defer bn.deinit();

  bn.uploadToGPU(c.GL_RGB8, &self.bluenoise);

  // `GL_RGB32F` is basically a requirement for HQ bloom
  gl.textures.init(@ptrCast(*[8 * 2]c.GLuint, &self.bloom), c.GL_RGB32F, 1, 1);
  gl.textures.init(&self.rendering, c.GL_RGB32F, 1, 1);
  gl.textures.init(&self.simulation, c.GL_RGB32F, 1, 1);

  return self;
}

pub fn deinit(self: *const Self) void {
  gl.textures.deinit(@ptrCast(*[1]c.GLuint, &self.bluenoise));
  gl.textures.deinit(@ptrCast(*[8 * 2]c.GLuint, &self.bloom));
  gl.textures.deinit(&self.rendering);
  gl.textures.deinit(&self.simulation);
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
