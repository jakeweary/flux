const c = @import("../c.zig");
const pixelfont = @import("../pixelfont.zig");
const std = @import("std");

pub const log = std.log.scoped(.imgui);
pub const Context = @import("Context.zig");

// ---

pub fn io() *c.ImGuiIO {
  return c.igGetIO();
}

pub fn style() *c.ImGuiStyle {
  return c.igGetStyle();
}

pub fn newFrame() void {
  c.ImGui_ImplOpenGL3_NewFrame();
  c.ImGui_ImplGlfw_NewFrame();
  c.igNewFrame();
}

pub fn render() void {
  c.igRender();
  c.ImGui_ImplOpenGL3_RenderDrawData(c.igGetDrawData());
}

// ---

pub fn text(str: []const u8) void {
  c.igTextUnformatted(str.ptr, str.ptr + str.len);
}

pub fn tooltip(str: []const u8) void {
  if (c.igIsItemHovered(0)) {
    c.igBeginTooltip();
    text(str);
    c.igEndTooltip();
  }
}

pub fn hint(str: []const u8) void {
  c.igSameLine(0, -1);
  c.igTextDisabled("?");
  tooltip(str);
}

pub fn plot(fmt: [*:0]const u8, height: f32, value: f32, storage: []f32) void {
  storage[0] = value;
  std.mem.rotate(f32, storage, 1);
  c.igPlotLines_FloatPtr("", storage.ptr, @intCast(c_int, storage.len),
    0, null, 0, c.igGET_FLT_MAX(), .{ .x = 0, .y = height }, @sizeOf(f32));
  c.igSameLine(0, -1);
  c.igText(fmt, @as(f64, value));
}

// ---

pub fn loadCustomStyle() void {
  const s = style();
  s.WindowPadding = .{ .x = 8, .y = 8 };
  s.FramePadding = .{ .x = 4, .y = 2 };
  s.ItemSpacing = .{ .x = 4, .y = 4 };
  s.IndentSpacing = 18;
  s.WindowBorderSize = 0;
  s.WindowRounding = 4;
  s.TabRounding = 2;
  s.FrameRounding = 2;
  s.GrabRounding = 1;
  s.GrabMinSize = 4;
  s.SeparatorTextBorderSize = 1;
  s.SeparatorTextPadding = .{ .x = 16, .y = 2 };
}

pub fn loadCustomPixelFont() void {
  const cfg: *c.ImFontConfig = c.ImFontConfig_ImFontConfig();
  defer c.ImFontConfig_destroy(cfg);
  cfg.SizePixels = 2 + pixelfont.HEIGHT;

  const font_atlas = io().Fonts;
  const font = c.ImFontAtlas_AddFontDefault(font_atlas, cfg);

  var ids: [pixelfont.CHARS.len]c_int = undefined;
  for (pixelfont.CHARS, 0..) |char, i|
    ids[i] = c.ImFontAtlas_AddCustomRectFontGlyph(font_atlas, font,
      char.code, pixelfont.WIDTH, pixelfont.HEIGHT, pixelfont.WIDTH + 1, .{ .x = 1, .y = 2 });

  var pixels: struct { ptr: [*c]u8, width: c_int } = undefined;
  c.ImFontAtlas_GetTexDataAsAlpha8(font_atlas, &pixels.ptr, &pixels.width, null, null);

  for (pixelfont.CHARS, 0..) |char, i| {
    const rect: *c.ImFontAtlasCustomRect = c
      .ImFontAtlas_GetCustomRectByIndex(font_atlas, ids[i]);

    const next_row = @intCast(usize, pixels.width);
    const first_row = @intCast(usize, pixels.width * rect.Y + rect.X);
    var row = pixels.ptr + first_row;

    for (0..rect.Height) |y| {
      for (0..rect.Width) |x| {
        const shift = @truncate(u6, pixelfont.WIDTH * y + x);
        row[x] = if (char.mask >> shift & 1 != 0) 0xff else 0;
      }
      row += next_row;
    }
  }
}
