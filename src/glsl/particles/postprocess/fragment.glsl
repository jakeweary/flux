uniform sampler2D tRendered;
uniform float uBrightness;
in vec2 vUV;
out vec3 fColor;

void main() {
  vec3 rendered = texture(tRendered, vUV).rgb;
  fColor = aces(uBrightness * rendered);
}
