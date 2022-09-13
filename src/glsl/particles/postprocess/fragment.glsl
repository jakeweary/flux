uniform sampler2D tRendered;
uniform float uBrightness;
uniform bool uAcesTonemapping;
in vec2 vUV;
out vec3 fColor;

void main() {
  vec3 color = uBrightness * texture(tRendered, vUV).rgb;
  fColor = uAcesTonemapping ? aces(color) : color;
}
