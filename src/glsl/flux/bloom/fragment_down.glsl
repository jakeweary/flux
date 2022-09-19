uniform sampler2D tSrc;
in vec2 vUV;
out vec3 fColor;

void main() {
  vec2 np = vec2(-1.0, 1.0); // negative/positive
  vec2 hp = 0.5 / vec2(textureSize(tSrc, 0)); // half pixel
  vec3 src =
    texture(tSrc, vUV + np.xx * hp).rgb +
    texture(tSrc, vUV + np.xy * hp).rgb +
    texture(tSrc, vUV + np.yx * hp).rgb +
    texture(tSrc, vUV + np.yy * hp).rgb;
  fColor = src / 4.0;
}
