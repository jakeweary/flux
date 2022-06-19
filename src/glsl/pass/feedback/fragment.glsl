uniform sampler2D tFeedback;
uniform float uT;
uniform float uDT;
in vec2 vUV;
out vec4 fColor;

float aspect_ratio(ivec2 size) {
  return float(size.x) / float(size.y);
}

vec2 from_angle(float angle) {
  return vec2(cos(angle), sin(angle));
}

// https://www.karlsims.com/rd.html
// https://www.karlsims.com/rdtool.html
vec2 xy_to_kf(vec2 xy) {
  vec2 uv = vec2(mix(1.0, (xy.y - 0.32) * (xy.y - 0.32), 0.6), 1.0) * xy * 0.5 + 0.5;
  float k = mix(mix(-0.003, 0.0115, uv.x), mix(-0.0048, -0.0031, uv.x), uv.y);
  float f = mix(0.002, 0.12, uv.y);
  return vec2(k + sqrt(f) * 0.5 - f, f);
}

vec2 warp(vec2 uv) {
  // float a = 5e-4 * sin(0.11 * uT);
  // mat2 r = mat2(cos(a), sin(a), -sin(a), cos(a));
  // return r * (1.0 - 1e-4 * sin(0.13 * uT)) * (uv - 0.5) + 0.5
  //   - vec2(1e-4 * sin(0.17 * uT), 1e-4 * sin(0.19 * uT));

  // return (1.0 - 1e-3) * (uv - 0.5) + 0.5;
  // return uv - vec2(2e-5, 2e-5);
  return uv;
}

vec4 laplacian(sampler2D t, vec2 uv) {
  // float size = 3.0 * smoothstep(0.8, 0.0, length(uv - 0.5));
  vec2 px = 1.0 / vec2(textureSize(t, 0));
  vec2 nw = texture(t, warp(uv + px * vec2(-1, +1))).xy;
  vec2 n  = texture(t, warp(uv + px * vec2(+0, +1))).xy;
  vec2 ne = texture(t, warp(uv + px * vec2(+1, +1))).xy;
  vec2 w  = texture(t, warp(uv + px * vec2(-1, +0))).xy;
  vec2 c  = texture(t, warp(uv)).xy;
  vec2 e  = texture(t, warp(uv + px * vec2(+1, +0))).xy;
  vec2 sw = texture(t, warp(uv + px * vec2(+1, -1))).xy;
  vec2 s  = texture(t, warp(uv + px * vec2(+0, -1))).xy;
  vec2 se = texture(t, warp(uv + px * vec2(-1, -1))).xy;
  return vec4(0.05 * (nw + ne + se + sw) + 0.2 * (n + s + w + e) - c, c);
}

vec2 reaction_diffusion(sampler2D t, vec2 uv, vec2 kf) {
  const vec2 d = vec2(1.0, 0.5);
  // const vec2 kf = xy_to_kf(2.0 * uv - 1.0);
  // const vec2 kf = vec2(0.062, 0.055);

  vec4 abab = laplacian(t, uv);
  float abb = abab.z * abab.w * abab.w;
  float a = abab.z + (d.x * abab.x - abb + kf.y * (1 - abab.z));
  float b = abab.w + (d.y * abab.y + abb - (kf.x + kf.y) * abab.w);
  return vec2(a, b);
}

void main() {
  float ar = aspect_ratio(textureSize(tFeedback, 0));
  vec2 uv = 2.0 * (vUV - 0.5) * vec2(ar, 1.0);

  float dist = 0.025 - length(0.0 * from_angle(5.0 * uT) - uv);
  float circle = 1.0 - clamp(100.0 * abs(dist), 0.0, 1.0);

  float k = simplex3d(vec3(uv, +0.1 * uT));
  float f = simplex3d(vec3(uv, -0.1 * uT));
  vec2 rd = reaction_diffusion(tFeedback, vUV, xy_to_kf(vec2(k, f)));

  // float k = mix(0.045, 0.07, 0.5 + 0.5 * simplex3d(vec3(uv, +0.1 * uT)));
  // float f = mix(0.01, 0.1, 0.5 + 0.5 * simplex3d(vec3(uv, -0.1 * uT)));
  // vec2 rd = reaction_diffusion(tFeedback, vUV, vec2(k, f));

  // vec2 uv = abs(vUV - 0.5);
  // vec2 ab = mix(
  //   vec2(1.0, 0.2 + 0.2 * ),
  //   rd,
  //   smoothstep(0.5, 0.49, max(uv.x, uv.y))
  // );

  vec2 ab = uT < 0.5
    ? vec2(1.0, 0.5 * circle)
    : rd;

  fColor = vec4(abb, 0.0, 1.0);

  // fColor = uT < 0.5
  //   ? vec4(1.0, 0.5 * circle, 0.0, 1.0)
  //   : vec4(rd, 0.0, 1.0);
}
