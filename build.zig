const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) !void {
  const target = b.standardTargetOptions(.{
    .default_target = try defaultTarget(),
  });

  const optimize = b.standardOptimizeOption(.{
    .preferred_optimize_mode = .ReleaseFast,
  });

  const deps = b.addModule("deps", .{
    .root_source_file = b.path("deps/deps.zig"),
  });

  const exe = b.addExecutable(.{
    .name = "flux",
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
  });
  exe.root_module.addImport("deps", deps);
  exe.linkLibC();
  exe.linkLibCpp();
  exe.addLibraryPath(b.path("deps/lib"));
  exe.addIncludePath(b.path("deps/include"));
  exe.addCSourceFile(.{ .file = b.path("deps/deps.c") });
  exe.addCSourceFile(.{ .file = b.path("deps/deps.cpp") });
  exe.linkSystemLibrary("glfw");
  switch (target.result.os.tag) {
    .windows => {
      exe.linkSystemLibrary("winmm");
      exe.linkSystemLibrary("gdi32");
      exe.linkSystemLibrary("opengl32");
    },
    .linux => {
      exe.linkSystemLibrary("X11");
      exe.linkSystemLibrary("GL");
    },
    else => @panic("unsupported os"),
  }
  b.installArtifact(exe);

  const run_cmd = b.addRunArtifact(exe);
  run_cmd.step.dependOn(b.getInstallStep());
  run_cmd.addArgs(b.args orelse &.{});

  const run_step = b.step("run", "Run the app");
  run_step.dependOn(&run_cmd.step);

  const exe_unit_tests = b.addTest(.{
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
  });

  const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

  const test_step = b.step("test", "Run unit tests");
  test_step.dependOn(&run_exe_unit_tests.step);
}

fn defaultTarget() !std.Target.Query {
  const is_wsl = builtin.os.tag == .linux and blk: {
    var buf: [1 << 10]u8 = undefined;
    const os = try std.fs.cwd().readFile("/proc/sys/kernel/osrelease", &buf);
    break :blk std.mem.containsAtLeast(u8, os, 1, "WSL");
  };
  return if (is_wsl) .{ .os_tag = .windows } else .{};
}
