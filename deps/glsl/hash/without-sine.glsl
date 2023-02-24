// https://www.shadertoy.com/view/4djSRW

#define MUL vec4(0.1031, 0.1030, 0.0973, 0.1099)
#define ADD 33.33

// ---

float hash11(float p) {
  p = fract(p * MUL.x);
  p *= p + ADD;
  p *= p + p;
  return fract(p);
}

float hash12(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * MUL.x);
  p3 += dot(p3, p3.yzx + ADD);
  return fract((p3.x + p3.y) * p3.z);
}

float hash13(vec3 p3) {
  p3 = fract(p3 * MUL.x);
  p3 += dot(p3, p3.zyx + 31.32);
  return fract((p3.x + p3.y) * p3.z);
}

float hash14(vec4 p4) {
  p4 = fract(p4 * MUL);
  p4 += dot(p4, p4.wzxy + ADD);
  return fract((p4.x + p4.y) * (p4.z + p4.w));
}

// ---

vec2 hash21(float p) {
  vec3 p3 = fract(vec3(p) * MUL.xyz);
  p3 += dot(p3, p3.yzx + ADD);
  return fract((p3.xx + p3.yz) * p3.zy);
}

vec2 hash22(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * MUL.xyz);
  p3 += dot(p3, p3.yzx + ADD);
  return fract((p3.xx + p3.yz) * p3.zy);
}

vec2 hash23(vec3 p3) {
  p3 = fract(p3 * MUL.xyz);
  p3 += dot(p3, p3.yzx + ADD);
  return fract((p3.xx + p3.yz) * p3.zy);
}

// ---

vec3 hash31(float p) {
  vec3 p3 = fract(vec3(p) * MUL.xyz);
  p3 += dot(p3, p3.yzx + ADD);
  return fract((p3.xxy + p3.yzz) * p3.zyx);
}

vec3 hash32(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * MUL.xyz);
  p3 += dot(p3, p3.yxz + ADD);
  return fract((p3.xxy + p3.yzz) * p3.zyx);
}

vec3 hash33(vec3 p3) {
  p3 = fract(p3 * MUL.xyz);
  p3 += dot(p3, p3.yxz + ADD);
  return fract((p3.xxy + p3.yxx) * p3.zyx);
}

// ---

vec4 hash41(float p) {
  vec4 p4 = fract(vec4(p) * MUL);
  p4 += dot(p4, p4.wzxy + ADD);
  return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

vec4 hash42(vec2 p) {
  vec4 p4 = fract(vec4(p.xyxy) * MUL);
  p4 += dot(p4, p4.wzxy + ADD);
  return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

vec4 hash43(vec3 p) {
  vec4 p4 = fract(vec4(p.xyzx) * MUL);
  p4 += dot(p4, p4.wzxy + ADD);
  return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

vec4 hash44(vec4 p4) {
  p4 = fract(p4 * MUL);
  p4 += dot(p4, p4.wzxy + ADD);
  return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}
