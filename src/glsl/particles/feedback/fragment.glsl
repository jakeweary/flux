uniform sampler2D tRendered;
uniform sampler2D tFeedback;
uniform float uMix;
in vec2 vUV;
out vec3 fColor;

void main() {
  vec3 r = texture(tRendered, vUV).rgb;
  vec3 f = texture(tFeedback, vUV).rgb;
  fColor = mix(r, f, uMix);
}
