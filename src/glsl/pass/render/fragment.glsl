uniform sampler2D tFeedback;
in vec2 vUV;
out vec4 fColor;

void main() {
  vec2 ab = texture(tFeedback, vUV).xy;
  // vec3 a = 0.3 * ab.x * vec3(0.1, 0.3, 1.0);
  // vec3 b = 9.0 * ab.y * vec3(1.0, 0.3, 0.1);
  // fColor = vec4(aces(a + b), 1.0);
  fColor = vec4(inferno(clamp(2.0 * ab.y, 0.0, 1.0)), 1.0);
  // fColor = vec4(turbo(clamp(0.5 - 0.5 * ab.x + ab.y, 0.0, 1.0)), 1.0);
}
