uniform sampler2D t_src;
uniform int u_src_lvl;
in vec2 v_uv;
out vec3 f_color;

const ivec3 s = ivec3(-1, 0, 1);

void main() {
  #if MODE == 0
    f_color = textureLod(t_src, v_uv, u_src_lvl).rgb;
  #elif MODE == 1
    vec3 a =
      textureLodOffset(t_src, v_uv, u_src_lvl, s.xx).rgb +
      textureLodOffset(t_src, v_uv, u_src_lvl, s.xz).rgb +
      textureLodOffset(t_src, v_uv, u_src_lvl, s.zx).rgb +
      textureLodOffset(t_src, v_uv, u_src_lvl, s.zz).rgb;
    f_color = a / 4.0;
  #elif MODE == 2
    // https://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare
    vec3 a =
      textureLod(t_src, v_uv, u_src_lvl).rgb +
      textureLodOffset(t_src, v_uv, u_src_lvl, s.xx).rgb +
      textureLodOffset(t_src, v_uv, u_src_lvl, s.xz).rgb +
      textureLodOffset(t_src, v_uv, u_src_lvl, s.zx).rgb +
      textureLodOffset(t_src, v_uv, u_src_lvl, s.zz).rgb;
    vec3 b =
      textureLodOffset(t_src, v_uv, u_src_lvl, s.xy).rgb +
      textureLodOffset(t_src, v_uv, u_src_lvl, s.zy).rgb +
      textureLodOffset(t_src, v_uv, u_src_lvl, s.yx).rgb +
      textureLodOffset(t_src, v_uv, u_src_lvl, s.yz).rgb;
    vec3 c =
      textureLodOffset(t_src, v_uv, u_src_lvl, s.xx * 2).rgb +
      textureLodOffset(t_src, v_uv, u_src_lvl, s.xz * 2).rgb +
      textureLodOffset(t_src, v_uv, u_src_lvl, s.zx * 2).rgb +
      textureLodOffset(t_src, v_uv, u_src_lvl, s.zz * 2).rgb;
    f_color = (a / 2.0 + b / 4.0 + c / 8.0) / 4.0;
  #elif MODE == 3
    // https://bartwronski.com/2022/03/07/fast-gpu-friendly-antialiasing-downsampling-filter/
    vec2 px = 1.0 / textureSize(t_src, u_src_lvl);
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
  #endif
}
