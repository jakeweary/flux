uniform sampler2D tRendered;
uniform float uBrightness;
in vec2 vUV;
out vec3 fColor;

void main() {
  vec3 color = uBrightness * texture(tRendered, vUV).rgb;

  #if ACES_TONEMAPPING
    fColor = aces(color);
  #else
    fColor = color;
  #endif
}
