const c = @import("../c.zig");
const std = @import("std");

pub fn uniform(location: c.GLint, value: anytype) void {
  switch (@typeInfo(@TypeOf(value))) {
    .ComptimeFloat => c.glUniform1f(location, value),
    .ComptimeInt => c.glUniform1i(location, value),
    .Float => c.glUniform1f(location, @floatCast(c.GLfloat, value)),
    .Int => |info| switch (info.signedness) {
      .signed => c.glUniform1i(location, @intCast(c.GLint, value)),
      .unsigned => c.glUniform1ui(location, @intCast(c.GLuint, value)),
    },
    .Bool => c.glUniform1i(location, @boolToInt(value)),
    .Pointer => {
      const Elem = std.meta.Elem(@TypeOf(value));
      const outer = switch (@typeInfo(Elem)) {
        .Array => |info| info,
        .Vector => |info| info,
        else => @typeInfo([1]Elem).Array
      };
      switch (@typeInfo(outer.child)) {
        // glUniformMatrix{2|3|4|2x3|3x2|2x4|4x2|3x4|4x3}fv
        .Array => |inner| {
          const matrix_fns = .{
            .{ c.glUniformMatrix2fv,   c.glUniformMatrix2x3fv, c.glUniformMatrix2x4fv },
            .{ c.glUniformMatrix3x2fv, c.glUniformMatrix3fv,   c.glUniformMatrix3x4fv },
            .{ c.glUniformMatrix4x2fv, c.glUniformMatrix4x3fv, c.glUniformMatrix4fv   },
          };
          const f = matrix_fns[outer.len - 2][inner.len - 2];
          f(location, @intCast(c_int, value.len), c.GL_FALSE, @ptrCast(*const inner.child, value));
        },
        // glUniform{1|2|3|4}{f|i|ui}v
        else => {
          const vector_fns = switch (outer.child) {
            c.GLfloat => .{ c.glUniform1fv,  c.glUniform2fv,  c.glUniform3fv,  c.glUniform4fv  },
            c.GLint   => .{ c.glUniform1iv,  c.glUniform2iv,  c.glUniform3iv,  c.glUniform4iv  },
            c.GLuint  => .{ c.glUniform1uiv, c.glUniform2uiv, c.glUniform3uiv, c.glUniform4uiv },
            else => @compileError("unimplemented")
          };
          const f = vector_fns[outer.len - 1];
          f(location, @intCast(c_int, value.len), @ptrCast(*const outer.child, value));
        }
      }
    },
    else => @compileError("unimplemented")
  }
}
