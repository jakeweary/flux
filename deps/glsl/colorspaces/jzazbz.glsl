const float b = 1.15;
const float g = 0.66;
const float c1 = 3424.0 / exp2(12.0);
const float c2 = 2413.0 / exp2(7.0);
const float c3 = 2392.0 / exp2(7.0);
const float n = 2610.0 / exp2(14.0);
const float p = 1.7 * 2523.0 / exp2(5.0);
const float d = -0.56;
const float d0 = 1.6295499532821566e-11;

const mat3 XYZ_to_LMS = 1e2 / 1e4 * mat3(
  +0.41478972, -0.20151000, -0.01660080,
  +0.57999900, +1.12064900, +0.26480000,
  +0.01464800, +0.05310080, +0.66847990
) * mat3(b, 1.0 - g, 0.0, 0.0, g, 0.0, 1.0 - b, 0.0, 1.0);

const mat3 LMS_to_Iab = mat3(
  +0.5, +3.524000, +0.199076,
  +0.5, -4.066708, +1.096799,
  +0.0, +0.542708, -1.295875
);

vec3 XYZ_to_Jab(vec3 XYZ) {
  vec3 LMS = XYZ_to_LMS * XYZ;
  vec3 LMSpp = pow(LMS, vec3(n));
  vec3 LMSp = pow((c1 + c2 * LMSpp) / (1.0 + c3 * LMSpp), vec3(p));
  vec3 Iab = LMS_to_Iab * LMSp;
  float J = (1.0 + d) * Iab.x / (1.0 + d * Iab.x) - d0;
  return vec3(J, Iab.yz);
}

vec3 Jab_to_XYZ(vec3 Jab) {
  float I = (Jab.x + d0) / (1.0 + d - d * (Jab.x + d0));
  vec3 LMSp = inverse(LMS_to_Iab) * vec3(I, Jab.yz);
  vec3 LMSpp = pow(LMSp, vec3(1.0 / p));
  vec3 LMS = pow((c1 - LMSpp) / (c3 * LMSpp - c2), vec3(1.0 / n));
  return inverse(XYZ_to_LMS) * LMS;
}

vec3 JCh_to_Jab(vec3 JCh) {
  return vec3(JCh.x, JCh.y * vec2(cos(JCh.z), sin(JCh.z)));
}

vec3 Jab_to_JCh(vec3 Jab) {
  return vec3(Jab.x, length(Jab.yz), atan(Jab.z, Jab.y));
}
