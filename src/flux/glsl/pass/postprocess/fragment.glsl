uniform sampler2D tRendered;
uniform sampler2D tBloom;
uniform sampler2D tBlueNoise;
uniform float uBrightness;
uniform float uBloomMix;
uniform int uBloomLvl;
in vec2 vUV;
out vec3 fColor;

void main() {
  vec3 r = texture(tRendered, vUV).rgb;
  vec3 b = textureLod(tBloom, vUV, uBloomLvl).rgb / textureQueryLevels(tBloom);
  vec3 color = uBrightness * mix(r, b, uBloomMix);

  #if ACES
    #if ACES_FAST
      color = aces(color);
    #else
      color = ODT_RGBmonitor_100nits_dim(RRT(mul(sRGB_2_AP0, color)));
    #endif
  #endif

  #if SRGB_OETF
    color = sRGB_OETF(color);
  #endif

  #if DITHER
    vec2 uv = gl_FragCoord.xy / vec2(textureSize(tBlueNoise, 0));
    color += texture(tBlueNoise, uv).rgb / 256.0;
  #endif

  fColor = color;
}
