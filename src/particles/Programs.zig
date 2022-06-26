const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const Self = @This();

const aces = @embedFile("../glsl/lib/aces.glsl");
const hashes = @embedFile("../glsl/lib/hashes.glsl");
const simplex3d = @embedFile("../glsl/lib/simplex3d.glsl");
const yab = @embedFile("../glsl/lib/yab.glsl");

seed: gl.Program,
update: gl.Program,
render: gl.Program,
postprocess: gl.Program,

pub fn init() !Self {
  var self: Self = undefined;

  self.seed = try blk: {
    const vs = @embedFile("../glsl/particles/seed/vertex.glsl");
    const fs = @embedFile("../glsl/particles/seed/fragment.glsl");
    break :blk gl.Program.init(&.{ vs }, &.{ hashes, fs });
  };
  errdefer self.seed.deinit();

  self.update = try blk: {
    const vs = @embedFile("../glsl/particles/update/vertex.glsl");
    const fs = @embedFile("../glsl/particles/update/fragment.glsl");
    break :blk gl.Program.init(&.{ vs }, &.{ simplex3d, fs });
  };
  errdefer self.update.deinit();

  self.render = try blk: {
    const vs = @embedFile("../glsl/particles/render/vertex.glsl");
    const fs = @embedFile("../glsl/particles/render/fragment.glsl");
    break :blk gl.Program.init(&.{ yab, vs }, &.{ fs });
  };
  errdefer self.render.deinit();

  self.postprocess = try blk: {
    const vs = @embedFile("../glsl/particles/postprocess/vertex.glsl");
    const fs = @embedFile("../glsl/particles/postprocess/fragment.glsl");
    break :blk gl.Program.init(&.{ vs }, &.{ aces, fs });
  };
  errdefer self.postprocess.deinit();

  return self;
}

pub fn deinit(self: *const Self) void {
  self.seed.deinit();
  self.update.deinit();
  self.render.deinit();
  self.postprocess.deinit();
}
