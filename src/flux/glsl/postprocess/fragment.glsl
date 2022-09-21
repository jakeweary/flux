uniform sampler2D tRendered;
uniform sampler2D tBloom;
uniform float uBrightness;
uniform float uBloomMix;
in vec2 vUV;
out vec3 fColor;

void main() {
  vec3 r = texture(tRendered, vUV).rgb;
  vec3 b = texture(tBloom, vUV).rgb / 8.0;
  vec3 color = uBrightness * mix(r, b, uBloomMix);

  #if ACES
    #if ACES_FAST
      color = aces(color);
    #else
      color = ODT_RGBmonitor_100nits_dim(RRT(color * sRGB_2_AP0));
    #endif
  #endif

  fColor = color;
}
