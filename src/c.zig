pub usingnamespace @cImport({
  @cInclude("glad/gl.h");
  @cInclude("GLFW/glfw3.h");
  @cInclude("stb_image.h");
  // @cInclude("linmath.h");

  @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", {});
  @cInclude("cimgui/cimgui.h");

  @cDefine("CIMGUI_USE_GLFW", {});
  @cDefine("CIMGUI_USE_OPENGL3", {});
  @cInclude("cimgui/cimgui_impl.h");
});
