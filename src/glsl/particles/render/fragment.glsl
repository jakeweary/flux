in vec2 vRadius;
in vec3 vColor;
out vec3 fColor;

void main() {
  #if RENDER_AS_LINES
    fColor = vColor;
  #else
    float dist = length(gl_PointCoord - 0.5);
    float circle = smoothstep(vRadius.x, vRadius.y, dist);
    fColor = circle * vColor;
  #endif
}
