uniform sampler2D tSrc;
in vec2 vUV;
out vec3 fColor;

void main() {
  vec2 k = vec2(-0.5, 0.5);
  vec2 px = 1.0 / vec2(textureSize(tSrc, 0));
  vec3 acc =
    texture(tSrc, vUV + k.xx * px).rgb +
    texture(tSrc, vUV + k.xy * px).rgb +
    texture(tSrc, vUV + k.yx * px).rgb +
    texture(tSrc, vUV + k.yy * px).rgb;
  fColor = acc / 4.0;
}
