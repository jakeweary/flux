const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const Self = @This();

seed: gl.Program,
update: gl.ProgramWithDefs(struct {
  RESPAWN_MODE: c_int = 0,
  WALLS_COLLISION: bool = false,
}),
render: gl.ProgramWithDefs(struct {
  COLORSPACE: c_int = 6,
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
  const srgb = @embedFile("../../deps/glsl/colorspaces/srgb.glsl");
  const lab = @embedFile("../../deps/glsl/colorspaces/cielab.glsl");
  const luv = @embedFile("../../deps/glsl/colorspaces/cieluv.glsl");
  const cam16 = @embedFile("../../deps/glsl/colorspaces/cam16.glsl");
  const jzazbz = @embedFile("../../deps/glsl/colorspaces/jzazbz.glsl");
  const oklab = @embedFile("../../deps/glsl/colorspaces/oklab.glsl");
  const hsl = @embedFile("../../deps/glsl/colorspaces/hsl.glsl");

  const aces = @embedFile("../../deps/glsl/aces.glsl");
  const aces_fast = @embedFile("../../deps/glsl/aces-fast.glsl");
  const hash = @embedFile("../../deps/glsl/hash/without-sine-2.glsl");
  const simplex3d = @embedFile("../../deps/glsl/simplex3d.glsl");

  const quad = @embedFile("glsl/quad/vertex.glsl");
  const quad_flip_y = @embedFile("glsl/quad/vertex_flip_y.glsl");

  var self: Self = undefined;

  self.seed = blk: {
    const vs = quad;
    const fs = @embedFile("glsl/pass/seed/fragment.glsl");
    break :blk try @TypeOf(self.seed).init(&.{ vs }, &.{ hash, fs });
  };
  errdefer self.seed.deinit();

  self.update = blk: {
    const vs = quad;
    const fs = @embedFile("glsl/pass/update/fragment.glsl");
    break :blk try @TypeOf(self.update).init(&.{ vs }, &.{ hash, simplex3d, fs });
  };
  errdefer self.update.deinit();

  self.render = blk: {
    const vs = @embedFile("glsl/pass/render/vertex.glsl");
    const fs = @embedFile("glsl/pass/render/fragment.glsl");
    break :blk try @TypeOf(self.render).init(&.{ srgb, lab, luv, cam16, jzazbz, oklab, hsl, vs }, &.{ fs });
  };
  errdefer self.render.deinit();

  self.feedback = blk: {
    const vs = quad;
    const fs = @embedFile("glsl/pass/feedback/fragment.glsl");
    break :blk try @TypeOf(self.feedback).init(&.{ vs }, &.{ fs });
  };
  errdefer self.feedback.deinit();

  self.postprocess = blk: {
    const vs = quad_flip_y;
    const fs = @embedFile("glsl/pass/postprocess/fragment.glsl");
    break :blk try @TypeOf(self.postprocess).init(&.{ vs }, &.{ aces, aces_fast, srgb, fs });
  };
  errdefer self.postprocess.deinit();

  self.bloom_blur = blk: {
    const vs = quad;
    const fs = @embedFile("glsl/pass/bloom/fragment_blur.glsl");
    break :blk try @TypeOf(self.bloom_blur).init(&.{ vs }, &.{ fs });
  };
  errdefer self.bloom_blur.deinit();

  self.bloom_down = blk: {
    const vs = quad;
    const fs = @embedFile("glsl/pass/bloom/fragment_down.glsl");
    break :blk try @TypeOf(self.bloom_down).init(&.{ vs }, &.{ fs });
  };
  errdefer self.bloom_down.deinit();

  self.bloom_up = blk: {
    const vs = quad;
    const fs = @embedFile("glsl/pass/bloom/fragment_up.glsl");
    break :blk try @TypeOf(self.bloom_up).init(&.{ vs }, &.{ fs });
  };
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
