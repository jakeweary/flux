uniform sampler2D tRendered;
in vec2 vUV;
out vec3 fColor;

void main() {
  vec3 rendered = texture(tRendered, vUV).rgb;
  fColor = aces(0.2 * rendered);
}
