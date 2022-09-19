uniform sampler2D tRendered;
uniform sampler2D tBloom;
uniform float uBrightness;
in vec2 vUV;
out vec3 fColor;

void main() {
  vec3 r = texture(tRendered, vUV).rgb;
  vec3 b = texture(tBloom, vUV).rgb;
  vec3 color = uBrightness * (r + b / 8.0);

  #if ACES_TONEMAPPING
    fColor = aces(color);
  #else
    fColor = color;
  #endif
}
