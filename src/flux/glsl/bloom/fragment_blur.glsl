uniform sampler2D tSrc;
uniform vec2 uDirection;
in vec2 vUV;
out vec3 fColor;

// https://stackoverflow.com/a/62002971#comment109661968_62002971
const int K = int(ceil(3.0 * SIGMA));

float gauss(float x) {
  const float k1 = 0.5 / (SIGMA * SIGMA);
  const float k2 = 1.0 / (SIGMA * sqrt(radians(360.0)));
  return exp(-x * x * k1) * k2;
}

void main() {
  vec2 px = uDirection / vec2(textureSize(tSrc, 0));
  vec3 acc = vec3(0.0);
  for (int i = -K; i <= K; i += 1) {
    float x = float(i);
    acc += gauss(x) * texture(tSrc, vUV + px * x).rgb;
  }
  fColor = acc;
}
