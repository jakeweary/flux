out vec2 f_age;
out vec2 f_position;
out vec2 f_velocity;

// https://en.wikipedia.org/wiki/Box-Muller_transform
vec2 normal(vec2 random) {
  float r = sqrt(-2.0 * log(1.0 - random.x));
  float theta = radians(360.0) * random.y;
  return r * vec2(sin(theta), cos(theta));
}

void main() {
  f_age = vec2(0);
  f_position = vec2(0);
  f_velocity = vec2(0);
  for (int i = 0; length(f_velocity) < 1e-3; i++)
    f_velocity = normal(hash23(uvec3(gl_FragCoord.xy, i)));
}
