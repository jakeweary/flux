uniform sampler2D tSize;
uniform sampler2D tColor;
uniform sampler2D tAge;
uniform sampler2D tPosition;
out vec2 vRadius;
out vec3 vColor;

void main() {
  ivec2 ts = textureSize(tSize, 0).xy;
  ivec2 uv = ivec2(gl_VertexID / ts.x, gl_VertexID % ts.x);

  float age = texelFetch(tAge, uv, 0).x;
  float size = texelFetch(tSize, uv, 0).x * smoothstep(0.0, 0.5, age);
  gl_PointSize = floor(size + 1.0);
  vRadius = vec2(size + 1.0, size - 1.0) / 2.0 / gl_PointSize;
  vColor = texelFetch(tColor, uv, 0).rgb * smoothstep(0.0, 0.1, age);

  gl_Position = vec4(texelFetch(tPosition, uv, 0).xy, 0.0, 1.0);
}
