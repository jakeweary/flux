// https://github.com/selfshadow/ltc_code/blob/master/webgl/shaders/ltc/ltc_blit.fs
// https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/ACES.hlsl
vec3 aces(vec3 color) {
  const mat3 x = mat3(+0.59719, +0.07600, +0.02840, +0.35458, +0.90834, +0.13383, +0.04823, +0.01566, +0.83777);
  const mat3 y = mat3(+1.60475, -0.10208, -0.00327, -0.53108, +1.10813, -0.07276, -0.07367, -0.00605, +1.07602);
  vec3 v = x * color;
  vec3 a = v * (v + 0.0245786) - 0.000090537;
  vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
  return clamp(y * (a / b), 0.0, 1.0);
}

// https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
float aces(float x) {
  return (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14);
}
