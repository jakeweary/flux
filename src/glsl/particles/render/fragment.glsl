in vec2 vRadius;
in float vSize;
out vec3 color;

void main() {
  float dist = length(gl_PointCoord - 0.5);
  float circle = (dist - vRadius.x) / (vRadius.y - vRadius.x);
  vec3 ych = vec3(0.5, 0.33, (vSize - 2.0) * radians(90.0) - radians(120.0));
  color = circle * yab_to_rgb * ych_to_yab(ych);
}
