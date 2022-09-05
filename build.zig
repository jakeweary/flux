const std = @import("std");
const builtin = @import("builtin");

fn isWSL() !bool {
  return builtin.os.tag == .linux and blk: {
    var buf: [1 << 10]u8 = undefined;
    const os = try std.fs.cwd().readFile("/proc/sys/kernel/osrelease", &buf);
    break :blk std.mem.containsAtLeast(u8, os, 1, "WSL");
  };
}

pub fn build(b: *std.build.Builder) !void {
  const mode = b.standardReleaseOptions();
  const target = b.standardTargetOptions(.{
    .default_target = if (try isWSL()) .{ .os_tag = .windows } else .{}
  });

  const exe = b.addExecutable("bin", "src/main.zig");
  exe.setMainPkgPath("");
  exe.setTarget(target);
  exe.setBuildMode(mode);
  exe.addLibraryPath("deps/lib");
  exe.addIncludePath("deps/include");
  exe.addCSourceFile("deps/deps.c", &.{});
  exe.addCSourceFile("deps/deps.cpp", &.{});
  exe.linkLibC();
  exe.linkLibCpp();
  exe.linkSystemLibraryName("glfw");
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
    else => @panic("unsupported os"),
  }
  exe.install();

  const run_cmd = exe.run();
  run_cmd.step.dependOn(b.getInstallStep());
  run_cmd.addArgs(b.args orelse &[_][]const u8{});

  const run_step = b.step("run", "Run the app");
  run_step.dependOn(&run_cmd.step);

  const exe_tests = b.addTest("src/tests.zig");
  exe_tests.setBuildMode(mode);

  const test_step = b.step("test", "Run unit tests");
  test_step.dependOn(&exe_tests.step);
}
