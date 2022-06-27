const std = @import("std");

pub fn build(b: *std.build.Builder) void {
  const mode = b.standardReleaseOptions();
  const target = b.standardTargetOptions(.{});

  const exe = b.addExecutable("bin", "src/main.zig");
  exe.single_threaded = true;
  exe.setTarget(target);
  exe.setBuildMode(mode);
  exe.addLibPath("deps/lib");
  exe.addIncludeDir("deps/include");
  exe.addCSourceFile("deps/impl.c", &.{"-std=c99"});
  exe.linkSystemLibraryName("glfw3");
  switch (exe.target.getOsTag()) {
    .windows => {
      exe.linkSystemLibraryName("winmm");
      exe.linkSystemLibraryName("gdi32");
      exe.linkSystemLibraryName("opengl32");
    },
    .linux => {
      exe.linkSystemLibraryName("X11");
      exe.linkSystemLibraryName("GL");
    },
    else => @panic("Unsupported OS")
  }
  exe.linkLibC();
  exe.install();

  const run_cmd = exe.run();
  run_cmd.step.dependOn(b.getInstallStep());
  run_cmd.addArgs(b.args orelse &.{});

  const run_step = b.step("run", "Run the app");
  run_step.dependOn(&run_cmd.step);

  const exe_tests = b.addTest("src/tests.zig");
  exe_tests.setBuildMode(mode);

  const test_step = b.step("test", "Run unit tests");
  test_step.dependOn(&exe_tests.step);
}
