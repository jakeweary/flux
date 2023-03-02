// https://arxiv.org/abs/1802.06067
// https://observablehq.com/@jrus/cam16

#define adapt_aux(x) pow(_F_L * abs(x), vec3(0.42))
#define adapt(x) 400.0 * sign(x) * adapt_aux(x) / (27.13 + adapt_aux(x))
#define unadapt(x) sign(x) / _F_L * pow(27.13 * abs(x) / (400.0 - abs(x)), vec3(1.0 / 0.42))

#define M16 mat3( \
  +0.401288, -0.250268, -0.002079, \
  +0.650173, +1.204414, +0.048952, \
  -0.051461, +0.045854, +0.953127)

// sRGB conditions, average surround
#define _XYZ_w D65
#define _Y_w _XYZ_w.y
#define _Y_b 0.2
#define _L_w (64.0 / radians(180.0))
#define _L_A (_L_w * _Y_b / _Y_w)
#define _F 1.0
#define _c 0.69
#define _N_c _F

// step 0*
#define _RGB_w (M16 * _XYZ_w)
#define _D 1.0 // clamp(_F * (1.0 - 1.0 / 3.6 * exp((-_L_A - 42.0) / 92.0)), 0.0, 1.0))
#define _D_RGB (_D * (_Y_w / _RGB_w) + 1.0 - _D)
#define _k4 pow(1.0 / (5.0 * _L_A + 1.0), 4.0)
#define _F_L (_k4 * _L_A + 0.1 * pow(1.0 - _k4, 2.0) * pow(5.0 * _L_A, 1.0 / 3.0))
#define _n (_Y_b / _Y_w)
#define _z (1.48 + sqrt(_n))
#define _N_bb (0.725 / pow(_n, 0.2))
#define _N_cb _N_bb
#define _RGB_cw (_D_RGB * _RGB_w)
#define _RGB_aw adapt(_RGB_cw)
#define _A_w (dot(vec3(2.0, 1.0, 0.05), _RGB_aw) * _N_bb)

vec3 XYZ_to_CAM16(vec3 XYZ) {
  // step 1
  vec3 RGB = M16 * XYZ;
  // step 2
  vec3 RGB_c = _D_RGB * RGB;
  // step 3*
  vec3 RGB_a = adapt(RGB_c);
  // step 4*
  const mat3x4 m = 1.0 / 1980.0 * mat3x4(
    3960.0, 1980.0, 220.0, 1980.0,
    1980.0, -2160.0, 220.0, 1980.0,
    99.0, 180.0, -440.0, 2079.0
  );
  vec4 aux = m * RGB_a; // p_2, a, b, u
  float h = atan(aux.z, aux.y);
  // step 5
  float e_t = 0.25 * (cos(h + 2.0) + 3.8);
  // step 6*
  float A = aux.x * _N_bb;
  // step 7
  float J = pow(A / _A_w, _c * _z);
  // step 8
  // step 9*
  float t = 5e4 / 13.0 * _N_c * _N_cb * e_t * length(aux.yz) / (aux.w + 0.305);
  float alpha = pow(t, 0.9) * pow(1.64 - pow(0.29, _n), 0.73);
  float C = 0.01 * alpha * sqrt(J);
  float M = C * pow(_F_L, 0.25);
  return vec3(J, M, h);
}

vec3 CAM16_to_XYZ(vec3 JMh) {
  // step 1
  // step 1-1
  // step 1-2*
  float C = JMh.y / pow(_F_L, 0.25);
  float alpha = JMh.x == 0.0 ? JMh.x : 100.0 * C / sqrt(JMh.x);
  float t = pow(alpha / pow(1.64 - pow(0.29, _n), 0.73), 1.0 / 0.9);
  // step 1-3
  // step 2*
  float e_t = 0.25 * (cos(JMh.z + 2.0) + 3.8);
  float A = _A_w * pow(JMh.x, 1.0 / (_c * _z));
  float p_1 = 5e4 / 13.0 * _N_c * _N_cb * e_t;
  float p_2 = A / _N_bb;
  // step 3*
  vec2 cs = vec2(cos(JMh.z), sin(JMh.z));
  float r = 23.0 * (p_2 + 0.305) * t / (23.0 * p_1 + t * dot(vec2(11.0, 108.0), cs));
  vec2 ab = r * cs;
  // step 4
  const mat3 m = 1.0 / 1403.0 * mat3(
    460.0, 460.0, 460.0,
    451.0, -891.0, -220.0,
    288.0, -261.0, -6300.0
  );
  vec3 RGB_a = m * vec3(p_2, ab);
  // step 5*
  vec3 RGB_c = unadapt(RGB_a);
  // step 6
  vec3 RGB = RGB_c / _D_RGB;
  // step 7
  return inverse(M16) * RGB;
}

vec3 XYZ_to_CAM16_UCS(vec3 XYZ) {
  vec3 JMh = XYZ_to_CAM16(XYZ);
  float J = 1.7 * JMh.x / (1.0 + 0.7 * JMh.x);
  float M = log(1.0 + 2.28 * JMh.y) / 2.28;
  return vec3(J, M, JMh.z);
}

vec3 CAM16_UCS_to_XYZ(vec3 JMh) {
  float J = JMh.x / (1.0 - 0.7 * (JMh.x - 1.0));
  float M = (exp(2.28 * JMh.y) - 1.0) / 2.28;
  return CAM16_to_XYZ(vec3(J, M, JMh.z));
}

#undef adapt_aux
#undef adapt
#undef unadapt

#undef M16

#undef _XYZ_w
#undef _Y_w
#undef _Y_b
#undef _L_w
#undef _L_A
#undef _F
#undef _c
#undef _N_c

#undef _RGB_w
#undef _D
#undef _D_RGB
#undef _k4
#undef _F_L
#undef _n
#undef _z
#undef _N_bb
#undef _N_cb
#undef _RGB_cw
#undef _RGB_aw
#undef _A_w
