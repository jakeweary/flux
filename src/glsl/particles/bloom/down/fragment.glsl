uniform sampler2D tSrc;
uniform bool uMultipleSamples;
in vec2 vUV;
out vec3 fColor;

void main() {
  if (uMultipleSamples) {
    vec2 np = vec2(-1.0, 1.0);
    vec2 px = 1.0 / vec2(textureSize(tSrc, 0));
    vec3 rgb =
      texture(tSrc, vUV + np.xx * px).rgb +
      texture(tSrc, vUV + np.xy * px).rgb +
      texture(tSrc, vUV + np.yx * px).rgb +
      texture(tSrc, vUV + np.yy * px).rgb;
    fColor = rgb / 4.0;
  }
  else {
    fColor = texture(tSrc, vUV).rgb;
  }
}
