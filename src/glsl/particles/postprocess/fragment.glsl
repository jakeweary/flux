uniform sampler2D tRendered;
uniform float uOpacity;
in vec2 vUV;
out vec3 fColor;

void main() {
  vec3 rendered = texture(tRendered, vUV).rgb;
  fColor = aces(uOpacity * rendered);
}
