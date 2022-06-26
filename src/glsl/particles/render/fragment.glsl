in vec2 vRadius;
in vec3 vColor;
out vec3 fColor;

float linearstep(float a, float b, float t) {
  return (t - a) / (b - a);
}

void main() {
  float dist = length(gl_PointCoord - 0.5);
  float circle = smoothstep(vRadius.x, vRadius.y, dist);
  fColor = circle * vColor;
}
