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

vec3 hue_to_color(float hue) {
  #if COLORSPACE == 0 // HSL
    return hsl_to_rgb(vec3(hue, 1.0, 0.5));
  #elif COLORSPACE == 1 // Smooth HSL
    return smooth_hsl_to_rgb(vec3(hue, 2.0, 0.5));
  #elif COLORSPACE == 2 // CIELAB
    vec3 LCh = vec3(0.722, 0.425, radians(360.0) * hue);
    return Lab_to_sRGB(LCh_to_Lab(LCh));
  #elif COLORSPACE == 3 // CIELUV
    vec3 LCh = vec3(0.760, 0.595, radians(360.0) * hue);
    return Luv_to_sRGB(LCh_to_Luv(LCh));
  #elif COLORSPACE == 4 // CAM16
    vec3 JMh = vec3(0.612, 0.348, radians(360.0) * hue);
    return XYZ_to_sRGB * CAM16_to_XYZ(JMh);
  #elif COLORSPACE == 5 // Jzazbz
    vec3 JCh = vec3(0.124, 0.059, radians(360.0) * hue);
    return XYZ_to_sRGB * Jzazbz_to_XYZ(JzCzhz_to_Jzazbz(JCh));
  #elif COLORSPACE == 6 // Oklab
    vec3 LCh = vec3(0.75, 0.125, radians(360.0) * hue);
    return XYZ_to_sRGB * Oklab_to_XYZ(Oklch_to_Oklab(LCh));
  #endif
}

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
  vec3 color = hue_to_color((uT - age) / 6.0);

  #if RENDER_AS_LINES
    vec2 vel = uDT * texelFetch(tVelocity, uv, 0).xy;

    #if LINE_RENDERING_MODE == 0 // don't normalize
      vec2 vel_px = uViewport * vel / 2.0;
      float len_px = max(1.0, length(vel_px));
      float scale = 1.0;
    #elif LINE_RENDERING_MODE == 1 // normalize (circle)
      vec2 vel_px = uViewport * vel / 2.0;
      float len_px = length(vel_px);
      float scale = max(1.0, 1.5 / len_px);
    #elif LINE_RENDERING_MODE == 2 // normalize (square)
      vec2 vel_px = abs(uViewport * vel / 2.0);
      float len_px = length(vel_px);
      float scale = max(1.0, 1.0 / max(vel_px.x, vel_px.y));
    #endif

    #if DYNAMIC_LINE_BRIGHTNESS
      color /= scale * len_px;
    #endif

    gl_Position = vec4(pos - scale * vel * id.y, 0.0, 1.0);
  #else
    #if FANCY_POINT_RENDERING
      gl_PointSize = floor(uPointScale + 1.0);
      vRadius = (uPointScale + vec2(-1.0, 1.0)) / (2.0 * gl_PointSize);
    #else
      gl_PointSize = 1.0;
    #endif

    gl_Position = vec4(pos, 0.0, 1.0);
  #endif

  vColor = spawn * color;
}
