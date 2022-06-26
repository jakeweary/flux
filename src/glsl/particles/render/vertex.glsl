uniform sampler2D tSize;
uniform sampler2D tPosition;
out vec2 vRadius;
out vec3 vColor;

void main() {
  ivec2 ts = textureSize(tSize, 0).xy;
  ivec2 uv = ivec2(gl_VertexID / ts.x, gl_VertexID % ts.x);
  gl_Position = vec4(texelFetch(tPosition, uv, 0).xy, 0.0, 1.0);

  float size = texelFetch(tSize, uv, 0).x;
  gl_PointSize = floor(size + 1.0);
  vRadius = vec2(size + 1.0, size - 1.0) / 2.0 / gl_PointSize;

  float hue = (size - 2.0) * (1.0 / 4.0) - (1.0 / 3.0);
  vColor = soft_hsl(vec3(hue, 2.0, 0.5));
}
