in vec2 vUV;
out float fSize;
out vec3 fColor;
out vec2 fVelocity;

// https://en.wikipedia.org/wiki/Box-Muller_transform
vec2 normal(vec2 random) {
  float r = sqrt(-2.0 * log(1.0 - random.x));
  float theta = radians(360.0) * random.y;
  return r * vec2(sin(theta), cos(theta));
}

void main() {
  fSize = 0.0;
  for (int i = 10; fSize < 1.0; i++)
    fSize = 3.0 + normal(hash23(vec3(1e3 * vUV, i))).x;

  float hue = (fSize - 3.0) * (1.0 / 8.0) - (1.0 / 3.0);
  fColor = soft_hsl(vec3(hue, 2.0, 0.5));

  fVelocity = vec2(0.0);
  for (int i = 10; length(fVelocity) < 1e-3; i++)
    fVelocity = normal(hash23(-vec3(1e3 * vUV, i)));
  fVelocity /= fSize;
}
