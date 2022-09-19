uniform sampler2D tSrc;
uniform sampler2D tAdd;
uniform vec2 uDirection;
in vec2 vUV;
out vec3 fColor;

void main() {
  vec2 px = uDirection / vec2(textureSize(tSrc, 0));
  vec3 acc = texture(tAdd, vUV).rgb;
  for (float x = -5.0; x <= 5.0; x += 1.0) {
    float o = 1.5;
    float g = exp(-x * x / (2.0 * o * o)) / (sqrt(radians(360.0)) * o);
    acc += g * texture(tSrc, vUV + px * x).rgb;
  }
  fColor = acc;
}
