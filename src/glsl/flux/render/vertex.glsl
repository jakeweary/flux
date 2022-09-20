uniform sampler2D tSize;
uniform sampler2D tColor;
uniform sampler2D tAge;
uniform sampler2D tPosition;
uniform sampler2D tVelocity;
uniform float uDT;
uniform float uPointScale;
uniform float uSmoothSpawn;
uniform ivec2 uViewport;
out vec2 vRadius;
out vec3 vColor;

void main() {
  #if RENDER_AS_LINES
    ivec2 id = ivec2(gl_VertexID / 2, gl_VertexID % 2);
  #else
    ivec2 id = ivec2(gl_VertexID, 0);
  #endif

  ivec2 ts = textureSize(tPosition, 0).xy;
  ivec2 uv = ivec2(id.x % ts.x, id.x / ts.x);

  vec2 pos = texelFetch(tPosition, uv, 0).xy;
  vec3 color = texelFetch(tColor, uv, 0).rgb;
  float age = texelFetch(tAge, uv, 0).x;
  float spawn = smoothstep(0.0, uSmoothSpawn, age);

  #if RENDER_AS_LINES
    vec2 vel = uDT * texelFetch(tVelocity, uv, 0).xy;
    gl_Position = vec4(pos - vel * float(id.y), 0.0, 1.0);

    #if DYNAMIC_LINE_BRIGHTNESS
      color /= max(1.0, length(vel * vec2(uViewport)));
    #endif
  #else
    gl_Position = vec4(pos, 0.0, 1.0);

    #if FANCY_POINT_RENDERING
      float size = uPointScale * texelFetch(tSize, uv, 0).x;
      gl_PointSize = floor(size + 1.0);
      vRadius = vec2(size + 1.0, size - 1.0) / 2.0 / gl_PointSize;
    #else
      gl_PointSize = 1.0;
    #endif
  #endif

  vColor = spawn * color;
}
