uniform sampler2D tFeedback;
uniform sampler2D tRendered;
uniform float uFeedback;
in vec2 vUV;
out vec3 fColor;

void main() {
  vec3 feedback = texture(tFeedback, vUV).rgb;
  vec3 rendered = texture(tRendered, vUV).rgb;
  fColor = uFeedback * feedback + rendered;
}
