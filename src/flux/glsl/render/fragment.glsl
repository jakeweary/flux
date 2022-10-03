in vec2 vRadius;
in vec3 vColor;
out vec3 fColor;

float linearstep(float edge0, float edge1, float x) {
  return clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
}

void main() {
  #if FANCY_POINT_RENDERING && !RENDER_AS_LINES
    float dist = length(gl_PointCoord - 0.5);
    #if POINT_EDGE_LINEARSTEP
      float circle = linearstep(vRadius.y, vRadius.x, dist);
    #else
      float circle = smoothstep(vRadius.y, vRadius.x, dist);
    #endif
    fColor = circle * vColor;
  #else
    fColor = vColor;
  #endif
}
