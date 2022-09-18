const c = @import("../c.zig");
const std = @import("std");

pub const log = std.log.scoped(.gl);
pub const debug = @import("debug.zig");
pub const textures = @import("textures.zig");
pub const Shader = @import("Shader.zig");
pub const ProgramBuilder = @import("ProgramBuilder.zig");
pub const ProgramInner = @import("ProgramInner.zig");
pub usingnamespace @import("Program.zig");

pub const String = std.ArrayList(c.GLchar);

pub const MAJOR = 4;
pub const MINOR = 6;
pub const VERSION = std.fmt.comptimePrint("#version {}{}0 core", .{ MAJOR, MINOR });

fn ReturnTypeOf(comptime method: @Type(.EnumLiteral)) type {
  const T = @TypeOf(@field(c, "gl" ++ @tagName(method)));
  return @typeInfo(T).Fn.return_type.?;
}

pub fn call(comptime method: @Type(.EnumLiteral), args: anytype) !ReturnTypeOf(method) {
  const result = @call(.{}, @field(c, "gl" ++ @tagName(method)), args);
  try debug.checkError();
  return result;
}
