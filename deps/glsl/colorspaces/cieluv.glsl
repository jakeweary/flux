// https://en.wikipedia.org/wiki/CIELUV
// http://www.brucelindbloom.com/Eqn_XYZ_to_Luv.html
// http://www.brucelindbloom.com/Eqn_Luv_to_XYZ.html

#define xyY_to_XYZ(x, y, Y) Y * vec3(x / y, 1.0, (1.0 - x - y) / y)
#define XYZ_to_uv(XYZ) XYZ.xy * vec2(4, 9) / dot(vec3(1, 15, 3), XYZ)
#define xy_to_uv(xy) xy * vec2(4, 9) / (dot(vec2(-2, 12), xy) + 3.0)
#define uv_to_xy(uv) uv * vec2(9, 4) / (dot(vec2(6, -16), uv) + 12.0)

vec3 XYZ_to_Luv(vec3 XYZ, vec3 XYZw) {
  float Y = XYZ.y / XYZw.y;
  float L = Y > 216.0 / 24389.0 ? 1.16 * pow(Y, 1.0 / 3.0) - 0.16 : 24389.0 / 2700.0 * Y;
  return vec3(L, 13.0 * L * (XYZ_to_uv(XYZ) - XYZ_to_uv(XYZw)));
}

vec3 Luv_to_XYZ(vec3 Luv, vec3 XYZw) {
  float Y = Luv.x > 0.08 ? pow((Luv.x + 0.16) / 1.16, 3.0) : 2700.0 / 24389.0 * Luv.x;
  vec2 uv = Luv.yz / (13.0 * Luv.x) + XYZ_to_uv(XYZw);
  vec2 xy = uv_to_xy(uv);
  return xyY_to_XYZ(xy.x, xy.y, Y) * XYZw.y;
}

vec3 LCh_to_Luv(vec3 LCh) {
  return vec3(LCh.x, LCh.y * vec2(cos(LCh.z), sin(LCh.z)));
}

vec3 Luv_to_LCh(vec3 Luv) {
  return vec3(Luv.x, length(Luv.yz), atan(Luv.z, Luv.y));
}

vec3 sRGB_to_Luv(vec3 sRGB) {
  return XYZ_to_Luv(sRGB_to_XYZ * sRGB, D65);
}

vec3 Luv_to_sRGB(vec3 Luv) {
  return XYZ_to_sRGB * Luv_to_XYZ(Luv, D65);
}

#undef xyY_to_XYZ
#undef XYZ_to_uv
#undef xy_to_uv
#undef uv_to_xy
