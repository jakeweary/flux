out vec2 v_uv;

void main() {
  v_uv = vec2(2 & gl_VertexID, 2 & gl_VertexID << 1);
  gl_Position = vec4(vec2(2.0, -2.0) * (v_uv - 0.5), 0.0, 1.0);
}
