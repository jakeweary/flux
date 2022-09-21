in vec2 vRadius;
in vec3 vColor;
out vec3 fColor;

void main() {
  #if FANCY_POINT_RENDERING && !RENDER_AS_LINES
    float dist = length(gl_PointCoord - 0.5);
    float circle = smoothstep(vRadius.x, vRadius.y, dist);
    fColor = circle * vColor;
  #else
    fColor = vColor;
  #endif
}
