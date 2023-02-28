in vec2 v_radius;
in vec3 v_color;
out vec3 f_color;

float linearstep(float edge0, float edge1, float x) {
  return clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
}

void main() {
  #if FANCY_POINT_RENDERING && !RENDER_AS_LINES
    float dist = length(gl_PointCoord - 0.5);
    #if POINT_EDGE_LINEARSTEP
      float circle = linearstep(v_radius.y, v_radius.x, dist);
    #else
      float circle = smoothstep(v_radius.y, v_radius.x, dist);
    #endif
    f_color = circle * v_color;
  #else
    f_color = v_color;
  #endif
}
