uniform sampler2D tRendered;
in vec2 vUV;
out vec3 color;

void main() {
  vec3 rendered = texture(tRendered, vUV).rgb;
  color = aces(0.1 * rendered);
}
