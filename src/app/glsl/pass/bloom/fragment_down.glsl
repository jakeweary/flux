uniform sampler2D t_src;
uniform int u_src_lvl;
in vec2 v_uv;
out vec3 f_color;

void main() {
  vec2 px = 1.0 / vec2(textureSize(t_src, u_src_lvl));
  vec3 s = vec3(-1.0, 0.0, 1.0);

  #if MODE == 3
    // https://bartwronski.com/2022/03/07/fast-gpu-friendly-antialiasing-downsampling-filter/
    vec2 k = vec2(0.75777, 2.907);
    vec3 a =
      textureLod(t_src, v_uv + k.x * s.xx * px, u_src_lvl).rgb +
      textureLod(t_src, v_uv + k.x * s.xz * px, u_src_lvl).rgb +
      textureLod(t_src, v_uv + k.x * s.zx * px, u_src_lvl).rgb +
      textureLod(t_src, v_uv + k.x * s.zz * px, u_src_lvl).rgb;
    vec3 b =
      textureLod(t_src, v_uv + k.y * s.xy * px, u_src_lvl).rgb +
      textureLod(t_src, v_uv + k.y * s.zy * px, u_src_lvl).rgb +
      textureLod(t_src, v_uv + k.y * s.yx * px, u_src_lvl).rgb +
      textureLod(t_src, v_uv + k.y * s.yz * px, u_src_lvl).rgb;
    f_color = 0.37487566 * a - 0.12487566 * b;
  #elif MODE == 2
    // https://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare
    vec3 a =
      textureLod(t_src, v_uv, u_src_lvl).rgb +
      textureLod(t_src, v_uv + s.xx * px, u_src_lvl).rgb +
      textureLod(t_src, v_uv + s.xz * px, u_src_lvl).rgb +
      textureLod(t_src, v_uv + s.zx * px, u_src_lvl).rgb +
      textureLod(t_src, v_uv + s.zz * px, u_src_lvl).rgb;
    vec3 b =
      textureLod(t_src, v_uv + s.xy * px, u_src_lvl).rgb +
      textureLod(t_src, v_uv + s.zy * px, u_src_lvl).rgb +
      textureLod(t_src, v_uv + s.yx * px, u_src_lvl).rgb +
      textureLod(t_src, v_uv + s.yz * px, u_src_lvl).rgb;
    vec3 c =
      textureLod(t_src, v_uv + 2.0 * s.xx * px, u_src_lvl).rgb +
      textureLod(t_src, v_uv + 2.0 * s.xz * px, u_src_lvl).rgb +
      textureLod(t_src, v_uv + 2.0 * s.zx * px, u_src_lvl).rgb +
      textureLod(t_src, v_uv + 2.0 * s.zz * px, u_src_lvl).rgb;
    f_color = (a / 2.0 + b / 4.0 + c / 8.0) / 4.0;
  #elif MODE == 1
    vec3 a =
      textureLod(t_src, v_uv + s.xx * px, u_src_lvl).rgb +
      textureLod(t_src, v_uv + s.xz * px, u_src_lvl).rgb +
      textureLod(t_src, v_uv + s.zx * px, u_src_lvl).rgb +
      textureLod(t_src, v_uv + s.zz * px, u_src_lvl).rgb;
    f_color = a / 4.0;
  #else
    f_color = textureLod(t_src, v_uv, u_src_lvl).rgb;
  #endif
}
