uniform sampler2D tSrc;
uniform int uSrcLvl;
uniform vec2 uDirection;
in vec2 vUV;
out vec3 fColor;

const int K = int(ceil(KERNEL_SCALE * SIGMA)) + 1;

// https://www.desmos.com/calculator/rgaxqrkuts
float gauss(float x) {
  const float k1 = 1.0 / (SIGMA * sqrt(radians(360.0)));
  const float k2 = 0.5 / (SIGMA * SIGMA);
  return k1 * exp(-k2 * x * x);
}

void main() {
  vec2 px = uDirection / vec2(textureSize(tSrc, uSrcLvl));
  vec3 acc = gauss(0.0) * textureLod(tSrc, vUV, uSrcLvl).rgb;

  #if BILINEAR_OPTIMIZATION
    // https://www.rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
    for (int i = 1; i < K; i += 2) {
      float x = float(i), w1 = gauss(x), w2 = gauss(x + 1.0);
      float x_linear = x + w2 / (w1 + w2);
      vec3 a = textureLod(tSrc, vUV - x_linear * px, uSrcLvl).rgb;
      vec3 b = textureLod(tSrc, vUV + x_linear * px, uSrcLvl).rgb;
      acc += (w1 + w2) * (a + b);
    }
  #else
    for (int i = 1; i < K; i++) {
      float x = float(i);
      vec3 a = textureLod(tSrc, vUV - x * px, uSrcLvl).rgb;
      vec3 b = textureLod(tSrc, vUV + x * px, uSrcLvl).rgb;
      acc += gauss(x) * (a + b);
    }
  #endif

  fColor = acc;
}
