uniform sampler2D tSrc;
uniform int uSrcLvl;
uniform vec2 uDirection;
in vec2 vUV;
out vec3 fColor;

// https://stackoverflow.com/a/62002971#comment109661968_62002971
const int K = int(ceil(KERNEL_SCALE * SIGMA));

float gauss(float x) {
  const float k1 = 1.0 / (SIGMA * sqrt(radians(360.0)));
  const float k2 = 0.5 / (SIGMA * SIGMA);
  return k1 * exp(-k2 * x * x);
}

void main() {
  vec2 px = uDirection / vec2(textureSize(tSrc, uSrcLvl));
  vec3 acc = gauss(0.0) * textureLod(tSrc, vUV, uSrcLvl).rgb;
  for (int i = 1; i <= K; i++) {
    float x = float(i);
    vec3 a = textureLod(tSrc, vUV - x * px, uSrcLvl).rgb;
    vec3 b = textureLod(tSrc, vUV + x * px, uSrcLvl).rgb;
    acc += gauss(x) * (a + b);
  }
  fColor = acc;
}
