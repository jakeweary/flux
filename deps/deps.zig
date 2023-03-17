pub const assets = struct {
  pub const bluenoise = @embedFile("assets/bluenoise/128/LDR_RGB1_0.png");
};

pub const shaders = struct {
  pub const colorspaces = struct {
    pub const srgb = @embedFile("glsl/colorspaces/srgb.glsl");
    pub const lab = @embedFile("glsl/colorspaces/cielab.glsl");
    pub const luv = @embedFile("glsl/colorspaces/cieluv.glsl");
    pub const cam16 = @embedFile("glsl/colorspaces/cam16.glsl");
    pub const jzazbz = @embedFile("glsl/colorspaces/jzazbz.glsl");
    pub const oklab = @embedFile("glsl/colorspaces/oklab.glsl");
    pub const hsl = @embedFile("glsl/colorspaces/hsl.glsl");
  };

  pub const aces = @embedFile("glsl/aces.glsl");
  pub const aces_fast = @embedFile("glsl/aces-fast.glsl");
  pub const hash = @embedFile("glsl/hash/without-sine-2.glsl");
  pub const simplex3d = @embedFile("glsl/simplex3d.glsl");
};
