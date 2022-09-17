uniform bool uRenderAsLines;
in vec2 vRadius;
in vec3 vColor;
out vec3 fColor;

void points() {
  float dist = length(gl_PointCoord - 0.5);
  float circle = smoothstep(vRadius.x, vRadius.y, dist);
  fColor = circle * vColor;
}

void lines() {
  fColor = vColor;
}

void main() {
  if (uRenderAsLines) lines(); else points();
}
