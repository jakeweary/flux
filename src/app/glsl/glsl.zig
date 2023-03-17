pub const quad = struct {
  pub const v = @embedFile("quad/vertex.glsl");
  pub const v_flip_y = @embedFile("quad/vertex_flip_y.glsl");
};

pub const pass = struct {
  pub const seed = struct {
    pub const f = @embedFile("pass/seed/fragment.glsl");
  };

  pub const update = struct {
    pub const f = @embedFile("pass/update/fragment.glsl");
  };

  pub const render = struct {
    pub const v = @embedFile("pass/render/vertex.glsl");
    pub const f = @embedFile("pass/render/fragment.glsl");
  };

  pub const feedback = struct {
    pub const f = @embedFile("pass/feedback/fragment.glsl");
  };

  pub const postprocess = struct {
    pub const f = @embedFile("pass/postprocess/fragment.glsl");
  };

  pub const bloom = struct {
    pub const f_blur = @embedFile("pass/bloom/fragment_blur.glsl");
    pub const f_down = @embedFile("pass/bloom/fragment_down.glsl");
    pub const f_up = @embedFile("pass/bloom/fragment_up.glsl");
  };
};
