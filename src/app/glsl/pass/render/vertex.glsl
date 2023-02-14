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
  #if COLORSPACE == 6 // Oklab
    vec3 LCh = vec3(0.75, 0.125, radians(360.0) * hue);
    return XYZ_to_sRGB * Oklab_to_XYZ(Oklch_to_Oklab(LCh));
  #elif COLORSPACE == 5 // Jzazbz
    vec3 JCh = vec3(0.124, 0.059, radians(360.0) * hue);
    return XYZ_to_sRGB * Jzazbz_to_XYZ(JzCzhz_to_Jzazbz(JCh));
  #elif COLORSPACE == 4 // CAM16
    vec3 JMh = vec3(0.612, 0.348, radians(360.0) * hue);
    return XYZ_to_sRGB * CAM16_to_XYZ(JMh);
  #elif COLORSPACE == 3 // CIELUV
    vec3 LCh = vec3(0.760, 0.595, radians(360.0) * hue);
    return Luv_to_sRGB(LCh_to_Luv(LCh));
  #elif COLORSPACE == 2 // CIELAB
    vec3 LCh = vec3(0.722, 0.425, radians(360.0) * hue);
    return Lab_to_sRGB(LCh_to_Lab(LCh));
  #elif COLORSPACE == 1 // Smooth HSL
    return smooth_hsl_to_rgb(vec3(hue, 2.0, 0.5));
  #else // HSL
    return hsl_to_rgb(vec3(hue, 1.0, 0.5));
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
