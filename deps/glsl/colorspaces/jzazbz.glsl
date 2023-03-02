// https://doi.org/10.1364/OE.25.015131
// https://observablehq.com/@jrus/jzazbz

#define _b 1.15
#define _g 0.66
#define _c1 (3424.0 / exp2(12.0))
#define _c2 (2413.0 / exp2(7.0))
#define _c3 (2392.0 / exp2(7.0))
#define _n (2610.0 / exp2(14.0))
#define _p (1.7 * 2523.0 / exp2(5.0))
#define _d -0.56
#define _d0 1.6295499532821566e-11

#define XYZ_to_LMS_adapted (1e2 / 1e4 * XYZ_to_LMS \
  * mat3(_b, 1.0 - _g, 0.0, 0.0, _g, 0.0, 1.0 - _b, 0.0, 1.0))

#define XYZ_to_LMS mat3( \
  +0.41478972, -0.20151000, -0.01660080, \
  +0.57999900, +1.12064900, +0.26480000, \
  +0.01464800, +0.05310080, +0.66847990)

#define LMS_to_Iab mat3( \
  +0.5, +3.524000, +0.199076, \
  +0.5, -4.066708, +1.096799, \
  +0.0, +0.542708, -1.295875)

vec3 XYZ_to_Jzazbz(vec3 XYZ) {
  vec3 LMS = XYZ_to_LMS_adapted * XYZ;
  vec3 LMSpp = pow(LMS, vec3(_n));
  vec3 LMSp = pow((_c1 + _c2 * LMSpp) / (1.0 + _c3 * LMSpp), vec3(_p));
  vec3 Iab = LMS_to_Iab * LMSp;
  float J = (1.0 + _d) * Iab.x / (1.0 + _d * Iab.x) - _d0;
  return vec3(J, Iab.yz);
}

vec3 Jzazbz_to_XYZ(vec3 Jab) {
  float I = (Jab.x + _d0) / (1.0 + _d - _d * (Jab.x + _d0));
  vec3 LMSp = inverse(LMS_to_Iab) * vec3(I, Jab.yz);
  vec3 LMSpp = pow(LMSp, vec3(1.0 / _p));
  vec3 LMS = pow((_c1 - LMSpp) / (_c3 * LMSpp - _c2), vec3(1.0 / _n));
  return inverse(XYZ_to_LMS_adapted) * LMS;
}

vec3 JzCzhz_to_Jzazbz(vec3 JCh) {
  return vec3(JCh.x, JCh.y * vec2(cos(JCh.z), sin(JCh.z)));
}

vec3 Jzazbz_to_JzCzhz(vec3 Jab) {
  return vec3(Jab.x, length(Jab.yz), atan(Jab.z, Jab.y));
}

#undef _b
#undef _g
#undef _c1
#undef _c2
#undef _c3
#undef _n
#undef _p
#undef _d
#undef _d0

#undef XYZ_to_LMS_adapted
#undef XYZ_to_LMS
#undef LMS_to_Iab
