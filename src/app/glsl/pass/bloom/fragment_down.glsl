uniform sampler2D tSrc;
uniform int uSrcLvl;
in vec2 vUV;
out vec3 fColor;

void main() {
  vec2 px = 1.0 / vec2(textureSize(tSrc, uSrcLvl));
  vec3 s = vec3(-1.0, 0.0, 1.0);

  #if MODE == 3
    // https://bartwronski.com/2022/03/07/fast-gpu-friendly-antialiasing-downsampling-filter/
    vec2 k = vec2(0.75777, 2.907);
    vec3 a =
      textureLod(tSrc, vUV + k.x * s.xx * px, uSrcLvl).rgb +
      textureLod(tSrc, vUV + k.x * s.xz * px, uSrcLvl).rgb +
      textureLod(tSrc, vUV + k.x * s.zx * px, uSrcLvl).rgb +
      textureLod(tSrc, vUV + k.x * s.zz * px, uSrcLvl).rgb;
    vec3 b =
      textureLod(tSrc, vUV + k.y * s.xy * px, uSrcLvl).rgb +
      textureLod(tSrc, vUV + k.y * s.zy * px, uSrcLvl).rgb +
      textureLod(tSrc, vUV + k.y * s.yx * px, uSrcLvl).rgb +
      textureLod(tSrc, vUV + k.y * s.yz * px, uSrcLvl).rgb;
    fColor = 0.37487566 * a - 0.12487566 * b;
  #elif MODE == 2
    // https://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare
    vec3 a =
      textureLod(tSrc, vUV, uSrcLvl).rgb +
      textureLod(tSrc, vUV + s.xx * px, uSrcLvl).rgb +
      textureLod(tSrc, vUV + s.xz * px, uSrcLvl).rgb +
      textureLod(tSrc, vUV + s.zx * px, uSrcLvl).rgb +
      textureLod(tSrc, vUV + s.zz * px, uSrcLvl).rgb;
    vec3 b =
      textureLod(tSrc, vUV + s.xy * px, uSrcLvl).rgb +
      textureLod(tSrc, vUV + s.zy * px, uSrcLvl).rgb +
      textureLod(tSrc, vUV + s.yx * px, uSrcLvl).rgb +
      textureLod(tSrc, vUV + s.yz * px, uSrcLvl).rgb;
    vec3 c =
      textureLod(tSrc, vUV + 2.0 * s.xx * px, uSrcLvl).rgb +
      textureLod(tSrc, vUV + 2.0 * s.xz * px, uSrcLvl).rgb +
      textureLod(tSrc, vUV + 2.0 * s.zx * px, uSrcLvl).rgb +
      textureLod(tSrc, vUV + 2.0 * s.zz * px, uSrcLvl).rgb;
    fColor = (a / 2.0 + b / 4.0 + c / 8.0) / 4.0;
  #elif MODE == 1
    vec3 a =
      textureLod(tSrc, vUV + s.xx * px, uSrcLvl).rgb +
      textureLod(tSrc, vUV + s.xz * px, uSrcLvl).rgb +
      textureLod(tSrc, vUV + s.zx * px, uSrcLvl).rgb +
      textureLod(tSrc, vUV + s.zz * px, uSrcLvl).rgb;
    fColor = a / 4.0;
  #else
    fColor = textureLod(tSrc, vUV, uSrcLvl).rgb;
  #endif
}
