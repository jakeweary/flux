uniform sampler2D tSrc;
in vec2 vUV;
out vec3 fColor;

void main() {
  vec2 px = 1.0 / vec2(textureSize(tSrc, 0));

  #if MODE == 2
    // https://bartwronski.com/2022/03/07/fast-gpu-friendly-antialiasing-downsampling-filter/
    vec3 s = vec3(-1.0, 0.0, 1.0);
    vec2 k = vec2(0.75777, 2.907);
    vec3 a =
      texture(tSrc, vUV + k.x * s.xx * px).rgb +
      texture(tSrc, vUV + k.x * s.xz * px).rgb +
      texture(tSrc, vUV + k.x * s.zx * px).rgb +
      texture(tSrc, vUV + k.x * s.zz * px).rgb;
    vec3 b =
      texture(tSrc, vUV + k.y * s.xy * px).rgb +
      texture(tSrc, vUV + k.y * s.zy * px).rgb +
      texture(tSrc, vUV + k.y * s.yx * px).rgb +
      texture(tSrc, vUV + k.y * s.yz * px).rgb;
    fColor = 0.37487566 * a - 0.12487566 * b;
  #elif MODE == 1
    vec2 k = vec2(-0.5, 0.5);
    vec3 acc =
      texture(tSrc, vUV + k.xx * px).rgb +
      texture(tSrc, vUV + k.xy * px).rgb +
      texture(tSrc, vUV + k.yx * px).rgb +
      texture(tSrc, vUV + k.yy * px).rgb;
    fColor = acc / 4.0;
  #else
    fColor = texture(tSrc, vUV).rgb;
  #endif
}
