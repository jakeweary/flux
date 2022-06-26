in vec2 vUV;
out float size;
out vec2 velocity;

// https://en.wikipedia.org/wiki/Box-Muller_transform
vec2 normal(vec2 random) {
  float r = sqrt(-2.0 * log(1.0 - random.x));
  float theta = radians(360.0) * random.y;
  return r * vec2(sin(theta), cos(theta));
}

void main() {
  size = 0.0;
  for (int i = 10; size < 1.0; i++)
    size = 2.0 + 0.5 * normal(hash23(vec3(1e3 * vUV, i))).x;

  velocity = vec2(0.0);
  for (int i = 10; length(velocity) < 0.1; i++)
    velocity = normal(hash23(-vec3(1e3 * vUV, i)));
  velocity *= 1e-2 / size;
}
