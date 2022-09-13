const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const imgui = @import("imgui.zig");
const font = @import("font.zig");
const Self = @This();

ctx: *c.ImGuiContext,
io: *c.ImGuiIO,
style: *c.ImGuiStyle,

pub fn init(window: *c.GLFWwindow) Self {
  const self = Self{
    .ctx = c.igCreateContext(null),
    .io = c.igGetIO(),
    .style = c.igGetStyle(),
  };
  _ = c.ImGui_ImplGlfw_InitForOpenGL(window, true);
  _ = c.ImGui_ImplOpenGL3_Init(gl.VERSION);
  return self;
}

pub fn deinit(self: *const Self) void {
  c.ImGui_ImplOpenGL3_Shutdown();
  c.ImGui_ImplGlfw_Shutdown();
  c.igDestroyContext(self.ctx);
}

pub fn newFrame(_: *const Self) void {
  c.ImGui_ImplOpenGL3_NewFrame();
  c.ImGui_ImplGlfw_NewFrame();
  c.igNewFrame();
}

pub fn render(_: *const Self) void {
  c.igRender();
  c.ImGui_ImplOpenGL3_RenderDrawData(c.igGetDrawData());
}

pub fn loadCustomStyle(self: *const Self) void {
  self.style.WindowPadding = .{ .x = 8, .y = 8 };
  self.style.FramePadding = .{ .x = 4, .y = 2 };
  self.style.ItemSpacing = .{ .x = 4, .y = 4 };
  self.style.IndentSpacing = 18;
  self.style.WindowBorderSize = 0;
  self.style.WindowRounding = 4;
  self.style.TabRounding = 2;
  self.style.FrameRounding = 2;
  self.style.GrabRounding = 1;
  self.style.GrabMinSize = 4;
}

pub fn loadCustomPixelFont(self: *const Self) void {
  const cfg: *c.ImFontConfig = c.ImFontConfig_ImFontConfig();
  defer c.ImFontConfig_destroy(cfg);
  cfg.SizePixels = 2 + font.HEIGHT;

  const font_ptr = c.ImFontAtlas_AddFontDefault(self.io.Fonts, cfg);

  var ids: [font.CHARS.len]c_int = undefined;
  for (font.CHARS) |char, i|
    ids[i] = c.ImFontAtlas_AddCustomRectFontGlyph(self.io.Fonts, font_ptr,
      char.code, font.WIDTH, font.HEIGHT, font.WIDTH + 1, .{ .x = 0, .y = 2 });

  var pixels: [*c]u8 = undefined;
  var pixels_width: c_int = undefined;
  c.ImFontAtlas_GetTexDataAsAlpha8(self.io.Fonts, &pixels, &pixels_width, null, null);

  for (font.CHARS) |char, i| {
    const rect: *c.ImFontAtlasCustomRect = c
      .ImFontAtlas_GetCustomRectByIndex(self.io.Fonts, ids[i]);

    const next_row = @intCast(usize, pixels_width);
    const first_row = @intCast(usize, pixels_width * rect.Y + rect.X);
    var row = pixels + first_row;

    var y: u6 = 0;
    while (y < rect.Height) : (y += 1) {
      var x: u6 = 0;
      while (x < rect.Width) : (x += 1) {
        const shift = font.WIDTH * y + x;
        row[x] = if (char.mask >> shift & 1 != 0) 0xff else 0;
      }
      row += next_row;
    }
  }
}
