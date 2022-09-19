uniform sampler2D tSrc;
uniform vec2 uDirection;
in vec2 vUV;
out vec3 fColor;

// https://stackoverflow.com/a/62002971#comment109661968_62002971
const int K = int(ceil(3.0 * SIGMA));

void main() {
  vec2 px = uDirection / vec2(textureSize(tSrc, 0));
  vec3 color = vec3(0.0);
  for (int i = -K; i <= K; i += 1) {
    float x = float(i);
    float g = exp(-x * x / (2.0 * SIGMA * SIGMA)) / (sqrt(radians(360.0)) * SIGMA);
    // float g = 1.0 / float(2 * K - 1);
    color += g * texture(tSrc, vUV + px * x).rgb;
  }
  fColor = color;
}