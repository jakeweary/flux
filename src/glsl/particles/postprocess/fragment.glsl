uniform sampler2D tPostprocess;
in vec2 vUV;
out vec3 color;

void main() {
  color = aces(0.1 * texture(tPostprocess, vUV).rgb);
}
