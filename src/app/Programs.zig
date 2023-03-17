const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const Self = @This();

const sh = @import("deps").shaders;
const cs = @import("deps").shaders.colorspaces;
const quad = @import("glsl/glsl.zig").quad;
const pass = @import("glsl/glsl.zig").pass;

seed: gl.Program,
update: gl.ProgramWithDefs(struct {
  RESPAWN_MODE: c_int = 0,
  WALLS_COLLISION: bool = false,
}),
render: gl.ProgramWithDefs(struct {
  COLORSPACE: c_int = 7,
  RENDER_AS_LINES: bool = true,
  LINE_RENDERING_MODE: c_int = 2,
  DYNAMIC_LINE_BRIGHTNESS: bool = true,
  FANCY_POINT_RENDERING: bool = false,
  POINT_EDGE_LINEARSTEP: bool = false,
}),
feedback: gl.Program,
postprocess: gl.ProgramWithDefs(struct {
  ACES: bool = true,
  ACES_FAST: bool = true,
  SRGB_OETF: bool = true,
  DITHER: bool = true,
}),
bloom_blur: gl.ProgramWithDefs(struct {
  SIGMA: f32 = 1.5,
  KERNEL_SCALE: f32 = 4.0,
  BILINEAR_OPTIMIZATION: bool = true,
}),
bloom_down: gl.ProgramWithDefs(struct {
  MODE: c_int = 0,
}),
bloom_up: gl.Program,

pub fn init() !Self {
  var self: Self = undefined;

  self.seed = try @TypeOf(self.seed).init(
    &.{ quad.v },
    &.{ sh.hash, pass.seed.f },
  );
  errdefer self.seed.deinit();

  self.update = try @TypeOf(self.update).init(
    &.{ quad.v },
    &.{ sh.hash, sh.simplex3d, pass.update.f },
  );
  errdefer self.update.deinit();

  self.render = try @TypeOf(self.render).init(
    &.{ cs.srgb, cs.lab, cs.luv, cs.cam16, cs.jzazbz, cs.oklab, cs.hsl, pass.render.v },
    &.{ pass.render.f },
  );
  errdefer self.render.deinit();

  self.feedback = try @TypeOf(self.feedback).init(
    &.{ quad.v },
    &.{ pass.feedback.f },
  );
  errdefer self.feedback.deinit();

  self.postprocess = try @TypeOf(self.postprocess).init(
    &.{ quad.v_flip_y },
    &.{ sh.aces, sh.aces_fast, cs.srgb, pass.postprocess.f },
  );
  errdefer self.postprocess.deinit();

  self.bloom_blur = try @TypeOf(self.bloom_blur).init(
    &.{ quad.v },
    &.{ pass.bloom.f_blur },
  );
  errdefer self.bloom_blur.deinit();

  self.bloom_down = try @TypeOf(self.bloom_down).init(
    &.{ quad.v },
    &.{ pass.bloom.f_down },
  );
  errdefer self.bloom_down.deinit();

  self.bloom_up = try @TypeOf(self.bloom_up).init(
    &.{ quad.v },
    &.{ pass.bloom.f_up },
  );
  errdefer self.bloom_up.deinit();

  return self;
}

pub fn deinit(self: *const Self) void {
  self.seed.deinit();
  self.update.deinit();
  self.render.deinit();
  self.feedback.deinit();
  self.postprocess.deinit();
  self.bloom_blur.deinit();
  self.bloom_down.deinit();
  self.bloom_up.deinit();
}

pub fn reinit(self: *Self) !void {
  _ = try self.seed.reinit();
  _ = try self.update.reinit();
  _ = try self.render.reinit();
  _ = try self.feedback.reinit();
  _ = try self.postprocess.reinit();
  _ = try self.bloom_blur.reinit();
  _ = try self.bloom_down.reinit();
  _ = try self.bloom_up.reinit();
}

pub fn defaults(self: *Self) void {
  self.seed.defs = .{};
  self.update.defs = .{};
  self.render.defs = .{};
  self.feedback.defs = .{};
  self.postprocess.defs = .{};
  self.bloom_blur.defs = .{};
  self.bloom_down.defs = .{};
  self.bloom_up.defs = .{};
}
