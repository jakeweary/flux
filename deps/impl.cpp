#include <glad/gl.h>

// #define IMGUI_DISABLE_OBSOLETE_KEYIO
#define IMGUI_DISABLE_OBSOLETE_FUNCTIONS
#define IMGUI_IMPL_OPENGL_LOADER_CUSTOM
#define IMGUI_IMPL_API extern "C"
#include <cimgui/imgui/imgui.cpp>
#include <cimgui/imgui/imgui_demo.cpp>
#include <cimgui/imgui/imgui_draw.cpp>
#include <cimgui/imgui/imgui_tables.cpp>
#include <cimgui/imgui/imgui_widgets.cpp>
#include <cimgui/imgui/imgui_impl_glfw.cpp>
#include <cimgui/imgui/imgui_impl_opengl3.cpp>

#include <cimgui/cimgui.cpp>
