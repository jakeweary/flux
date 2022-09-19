const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const Self = @This();

const aces = @embedFile("../glsl/lib/aces.glsl");
const oklab = @embedFile("../glsl/lib/oklab.glsl");
const srgb = @embedFile("../glsl/lib/srgb.glsl");

const hashes = @embedFile("../glsl/lib/hashes.glsl");
const simplex3d = @embedFile("../glsl/lib/simplex3d.glsl");

seed: gl.Program,
update: gl.ProgramWithDefs(struct {
  WALLS_COLLISION: bool = false,
}),
render: gl.ProgramWithDefs(struct {
  RENDER_AS_LINES: bool = true,
  DYNAMIC_LINE_BRIGHTNESS: bool = true,
  FANCY_POINT_RENDERING: bool = true,
}),
feedback: gl.Program,
postprocess: gl.ProgramWithDefs(struct {
  ACES_TONEMAPPING: bool = true,
}),
bloom_down: gl.Program,
bloom_up: gl.Program,

pub fn init() !Self {
  var self: Self = undefined;

  self.seed = blk: {
    const vs = @embedFile("../glsl/particles/seed/vertex.glsl");
    const fs = @embedFile("../glsl/particles/seed/fragment.glsl");
    break :blk try @TypeOf(self.seed).init(&.{ vs }, &.{ hashes, srgb, oklab, fs });
  };
  errdefer self.seed.deinit();

  self.update = blk: {
    const vs = @embedFile("../glsl/particles/update/vertex.glsl");
    const fs = @embedFile("../glsl/particles/update/fragment.glsl");
    break :blk try @TypeOf(self.update).init(&.{ vs }, &.{ hashes, simplex3d, fs });
  };
  errdefer self.update.deinit();

  self.render = blk: {
    const vs = @embedFile("../glsl/particles/render/vertex.glsl");
    const fs = @embedFile("../glsl/particles/render/fragment.glsl");
    break :blk try @TypeOf(self.render).init(&.{ vs }, &.{ fs });
  };
  errdefer self.render.deinit();

  self.feedback = blk: {
    const vs = @embedFile("../glsl/particles/feedback/vertex.glsl");
    const fs = @embedFile("../glsl/particles/feedback/fragment.glsl");
    break :blk try @TypeOf(self.feedback).init(&.{ vs }, &.{ fs });
  };
  errdefer self.feedback.deinit();

  self.postprocess = blk: {
    const vs = @embedFile("../glsl/particles/postprocess/vertex.glsl");
    const fs = @embedFile("../glsl/particles/postprocess/fragment.glsl");
    break :blk try @TypeOf(self.postprocess).init(&.{ vs }, &.{ aces, fs });
  };
  errdefer self.postprocess.deinit();

  self.bloom_down = blk: {
    const vs = @embedFile("../glsl/particles/bloom/down/vertex.glsl");
    const fs = @embedFile("../glsl/particles/bloom/down/fragment.glsl");
    break :blk try @TypeOf(self.bloom_down).init(&.{ vs }, &.{ fs });
  };
  errdefer self.bloom_down.deinit();

  self.bloom_up = blk: {
    const vs = @embedFile("../glsl/particles/bloom/up/vertex.glsl");
    const fs = @embedFile("../glsl/particles/bloom/up/fragment.glsl");
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
  self.bloom_down.deinit();
  self.bloom_up.deinit();
}

pub fn reinit(self: *Self) !void {
  _ = try self.seed.reinit();
  _ = try self.update.reinit();
  _ = try self.render.reinit();
  _ = try self.feedback.reinit();
  _ = try self.postprocess.reinit();
  _ = try self.bloom_down.reinit();
  _ = try self.bloom_up.reinit();
}

pub fn defaults(self: *Self) void {
  self.seed.defs = .{};
  self.update.defs = .{};
  self.render.defs = .{};
  self.feedback.defs = .{};
  self.postprocess.defs = .{};
  self.bloom_down.defs = .{};
  self.bloom_up.defs = .{};
}
