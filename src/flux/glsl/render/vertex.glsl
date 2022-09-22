uniform sampler2D tAge;
uniform sampler2D tPosition;
uniform sampler2D tVelocity;
uniform float uT;
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
  float age = texelFetch(tAge, uv, 0).x;
  float spawn = smoothstep(0.0, uSmoothSpawn, age);
  vec3 color = Lab_to_sRGB(LCh_to_Lab(vec3(0.75, 0.125, radians(60.0) * (uT - age))));

  #if RENDER_AS_LINES
    vec2 vel = uDT * texelFetch(tVelocity, uv, 0).xy;
    gl_Position = vec4(pos - vel * float(id.y), 0.0, 1.0);

    #if DYNAMIC_LINE_BRIGHTNESS
      color /= max(1.0, length(vel * vec2(uViewport)));
    #endif
  #else
    gl_Position = vec4(pos, 0.0, 1.0);

    #if FANCY_POINT_RENDERING
      gl_PointSize = floor(uPointScale + 1.0);
      vRadius = (uPointScale + vec2(-1.0, 1.0)) / (2.0 * gl_PointSize);
    #else
      gl_PointSize = 1.0;
    #endif
  #endif

  vColor = spawn * color;
}
