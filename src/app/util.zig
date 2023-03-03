const std = @import("std");

pub inline fn logarithmic(amp: f32, t: f32) f32 {
  return (@exp(t * amp) - 1) / (@exp(amp) - 1);
}

pub inline fn swap(comptime T: type, pair: *[2]T) void {
  std.mem.swap(T, &pair[0], &pair[1]);
}

// https://imois.in/posts/random-vectors-and-rotations-in-3d/#Quaternions
// https://doi.org/10.1016/B978-0-08-050755-2.50036-1
pub fn randomRotationMatrix(comptime T: type, r: *std.rand.Random) [3][3]T {
  return quatToMatrix(T, randomQuat(T, r));
}

fn randomQuat(comptime T: type, r: *std.rand.Random) [4]T {
  const x = r.floatNorm(T);
  const y = r.floatNorm(T);
  const z = r.floatNorm(T);
  const w = r.floatNorm(T);
  return .{ x, y, z, w };
}

// https://github.com/recp/cglm/blob/bc8dc727/include/cglm/quat.h#L555
fn quatToMatrix(comptime T: type, q: [4]T) [3][3]T {
  @setFloatMode(.Optimized);
  const x = q[0];
  const y = q[1];
  const z = q[2];
  const w = q[3];
  const s = 2 / (x * x + y * y + z * z + w * w);
  const xx = s * x * x;
  const xy = s * x * y;
  const wx = s * w * x;
  const yy = s * y * y;
  const yz = s * y * z;
  const wy = s * w * y;
  const zz = s * z * z;
  const xz = s * x * z;
  const wz = s * w * z;
  return .{
    .{ 1 - yy - zz, xy + wz, xz - wy },
    .{ xy - wz, 1 - xx - zz, yz + wx },
    .{ xz + wy, yz - wx, 1 - xx - yy },
  };
}
