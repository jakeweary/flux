uniform sampler2D tA;
uniform sampler2D tB;
in vec2 vUV;
out vec3 fColor;

void main() {
  vec3 a = texture(tA, vUV).rgb;
  vec3 b = texture(tB, vUV).rgb;
  fColor = a + b;
}
