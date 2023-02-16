in vec2 vUV;
out vec2 fPosition;
out vec2 fVelocity;

// https://en.wikipedia.org/wiki/Box-Muller_transform
vec2 normal(vec2 random) {
  float r = sqrt(-2.0 * log(1.0 - random.x));
  float theta = radians(360.0) * random.y;
  return r * vec2(sin(theta), cos(theta));
}

void main() {
  fPosition = vec2(0.0);
  fVelocity = vec2(0.0);
  for (int i = 0; length(fVelocity) < 1e-3; i++)
    fVelocity = normal(hash23(vec3(1e3 * vUV, i)));
}
