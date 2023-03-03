in vec2 v_radius;
in vec3 v_color;
out vec3 f_color;

float linearstep(float edge0, float edge1, float x) {
  return clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
}

float circle(vec2 radius, float dist) {
  #if POINT_EDGE_LINEARSTEP
    return linearstep(radius.y, radius.x, dist);
  #else
    return smoothstep(radius.y, radius.x, dist);
  #endif
}

void main() {
  #if FANCY_POINT_RENDERING && !RENDER_AS_LINES
    float mask = circle(v_radius, length(gl_PointCoord - 0.5));
  #else
    float mask = 1.0;
  #endif

  f_color = mask * v_color;
}
