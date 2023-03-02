uniform sampler2D t_rendered;
uniform sampler2D t_bloom;
uniform sampler2D t_blue_noise;
uniform float u_brightness;
uniform float u_bloom_mix;
uniform int u_bloom_lvl;
in vec2 v_uv;
out vec3 f_color;

void main() {
  vec3 r = texture(t_rendered, v_uv).rgb;
  vec3 b = textureLod(t_bloom, v_uv, u_bloom_lvl).rgb / textureQueryLevels(t_bloom);
  vec3 color = u_brightness * mix(r, b, u_bloom_mix);

  #if ACES
    #if ACES_FAST
      color = aces(color);
    #else
      color = ODT_RGBmonitor_100nits_dim(RRT(color * sRGB_2_AP0));
    #endif
  #endif

  #if SRGB_OETF
    color = sRGB_OETF(color);
  #endif

  #if DITHER
    vec2 uv = gl_FragCoord.xy / vec2(textureSize(t_blue_noise, 0));
    color += texture(t_blue_noise, uv).rgb / 256.0;
  #endif

  f_color = color;
}
