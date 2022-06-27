uniform sampler2D tSize;
uniform sampler2D tColor;
uniform sampler2D tAge;
uniform sampler2D tPosition;
out vec2 vRadius;
out vec3 vColor;

void main() {
  ivec2 ts = textureSize(tSize, 0).xy;
  ivec2 uv = ivec2(gl_VertexID / ts.x, gl_VertexID % ts.x);

  float size = texelFetch(tSize, uv, 0).x;
  gl_PointSize = floor(size + 1.0);
  vRadius = vec2(size + 1.0, size - 1.0) / 2.0 / gl_PointSize;

  float age = texelFetch(tAge, uv, 0).x;
  vec3 color = texelFetch(tColor, uv, 0).rgb;
  vColor = smoothstep(0.0, 0.2, age) * color;

  gl_Position = vec4(texelFetch(tPosition, uv, 0).xy, 0.0, 1.0);
}
