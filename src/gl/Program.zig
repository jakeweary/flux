const c = @import("../c.zig");
const gl = @import("gl.zig");
const root = @import("root");
const std = @import("std");

pub const Program = ProgramWithDefs(struct {});

pub fn ProgramWithDefs(comptime Defs: type) type {
  const fields = switch (@typeInfo(Defs)) {
    .Struct => |s| s.fields,
    else => unreachable,
  };

  return struct {
    const NameAndId = std.meta.Tuple(&.{ [*:0]const c.GLchar, c.GLuint });
    const Self = @This();

    id: c.GLuint,
    defs: Defs = .{},
    prev: Defs = .{},
    vert: [:0]const c.GLchar,
    frag: [:0]const c.GLchar,

    pub fn init(vert: []const []const c.GLchar, frag: []const []const c.GLchar) !Self {
      const vert_z = try std.mem.joinZ(root.allocator, "\n", vert);
      errdefer root.allocator.free(vert_z);

      const frag_z = try std.mem.joinZ(root.allocator, "\n", frag);
      errdefer root.allocator.free(frag_z);

      const id = try build(vert_z, frag_z, .{});
      return .{ .id = id, .vert = vert_z, .frag = frag_z };
    }

    pub fn deinit(self: *const Self) void {
      root.allocator.free(self.frag);
      root.allocator.free(self.vert);
      c.glDeleteProgram(self.id);
    }

    pub fn reinit(self: *Self) !bool {
      const changed = !std.meta.eql(self.defs, self.prev);
      if (changed) {
        c.glDeleteProgram(self.id);
        self.id = try build(self.vert, self.frag, self.defs);
        self.prev = self.defs;
      }
      return changed;
    }

    pub fn attribute(self: *const Self, name: [*:0]const c.GLchar) c.GLuint {
      return @intCast(c.GLuint, c.glGetAttribLocation(self.id, name));
    }

    pub fn uniform(self: *const Self, name: [*:0]const c.GLchar) c.GLint {
      return c.glGetUniformLocation(self.id, name);
    }

    pub fn use(self: *const Self) void {
      c.glUseProgram(self.id);
    }

    pub fn bindTexture(self: *const Self, name: [*:0]const c.GLchar, unit: c.GLuint, id: c.GLuint) void {
      c.glBindTextureUnit(unit, id);
      c.glUniform1i(c.glGetUniformLocation(self.id, name), @intCast(c.GLint, unit));
    }

    pub fn bindTextures(self: *const Self, pairs: []const NameAndId) void {
      for (pairs) |pair, i|
        self.bindTexture(pair[0], @intCast(c.GLuint, i), pair[1]);
    }

    // here goes my attempt to cover (almost) all of `glUniform{1|2|3|4}{f|i|ui}[v]`
    pub fn bind(self: *const Self, name: [*:0]const c.GLchar, value: anytype) void {
      const loc = self.uniform(name);
      switch (@typeInfo(@TypeOf(value))) {
        .ComptimeFloat, .Float => c.glUniform1f(loc, @floatCast(c.GLfloat, value)),
        .ComptimeInt, .Int => c.glUniform1i(loc, @intCast(c.GLint, value)),
        .Bool => c.glUniform1i(loc, @boolToInt(value)),
        .Pointer => |ptr| {
          const T = switch (ptr.size) {
            .Slice => ptr.child,
            .One => std.meta.Child(ptr.child),
            else => @compileError("unimplemented")
          };
          const vec = switch (@typeInfo(T)) {
            .Array => |info| info,
            .Vector => |info| info,
            else => @typeInfo([1]T).Array
          };
          const kind = switch (vec.child) {
            c.GLfloat => "f",
            c.GLint => "i",
            c.GLuint => "ui",
            else => @compileError("unimplemented")
          };
          const method = comptime std.fmt.comptimePrint("glUniform{}{s}v", .{ vec.len, kind });
          @field(c, method)(loc, @intCast(c_int, value.len), @ptrCast(*const vec.child, value));
        },
        else => @compileError("unimplemented")
      }
    }

    fn build(vert: [:0]const c.GLchar, frag: [:0]const c.GLchar, defs: Defs) !c.GLuint {
      var str = gl.String.init(root.allocator);
      defer str.deinit();

      const header = try writeHeader(&str, defs);
      const builder = gl.ProgramBuilder.init();
      try builder.attach(c.GL_VERTEX_SHADER, &.{ header, vert });
      try builder.attach(c.GL_FRAGMENT_SHADER, &.{ header, frag });
      return builder.link();
    }

    fn writeHeader(str: *gl.String, defs: Defs) ![:0]c.GLchar {
      const str_w = str.writer();

      try str.appendSlice(gl.VERSION ++ "\n");
      inline for (fields) |f| {
        const k = f.name;
        const v = @field(defs, f.name);
        const kv = switch (f.field_type) {
          bool => .{ k, @boolToInt(v) },
          else => .{ k, v },
        };
        const fmt = switch (f.field_type) {
          []const c.GLchar => "{s}",
          else => "{}",
        };
        try str_w.print("#define {s} " ++ fmt ++ "\n", kv);
      }
      try str.appendSlice("\n\x00");

      return str.items[0 .. str.items.len - 1 :0];
    }
  };
}
