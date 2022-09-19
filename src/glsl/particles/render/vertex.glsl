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
    ivec2 ts = textureSize(tPosition, 0).xy;
    ivec2 id = ivec2(gl_VertexID % 2, gl_VertexID / 2);
    ivec2 uv = ivec2(id.y % ts.x, id.y / ts.x);

    float age = texelFetch(tAge, uv, 0).x;
    float spawn = smoothstep(0.0, uSmoothSpawn, age);
    vec2 pos = texelFetch(tPosition, uv, 0).xy;
    vec2 vel = texelFetch(tVelocity, uv, 0).xy * uDT;
    vec2 travel = mix(vec2(0.0), vel, age != 0.0 && id.x != 0);
    gl_Position = vec4(pos - travel, 0.0, 1.0);

    #if DYNAMIC_LINE_BRIGHTNESS
      float len = max(1.0, length(vel * vec2(uViewport)));
    #else
      float len = 1.0;
    #endif

    vColor = texelFetch(tColor, uv, 0).rgb * spawn / len;
  #else
    ivec2 ts = textureSize(tPosition, 0).xy;
    ivec2 uv = ivec2(gl_VertexID % ts.x, gl_VertexID / ts.x);

    float age = texelFetch(tAge, uv, 0).x;
    float spawn = smoothstep(0.0, uSmoothSpawn, age);
    vec2 pos = texelFetch(tPosition, uv, 0).xy;
    gl_Position = vec4(pos, 0.0, 1.0);

    #if FANCY_POINT_RENDERING
      float size = uPointScale * texelFetch(tSize, uv, 0).x;
      gl_PointSize = floor(size + 1.0);
      vRadius = vec2(size + 1.0, size - 1.0) / 2.0 / gl_PointSize;
    #else
      gl_PointSize = 1.0;
    #endif

    vColor = texelFetch(tColor, uv, 0).rgb * spawn;
  #endif
}
