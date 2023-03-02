// https://www.shadertoy.com/view/4djSRW

#define MUL uvec4(1597334673u, 3812015801u, 2798796415u, 1979697957u)
#define INV (1.0 / float(0xffffffffu))

// ---

float hash11(uint q) {
  uvec2 n = q * MUL.xy;
  q = (n.x ^ n.y) * MUL.x;
  return float(q) * INV;
}

float hash12(uvec2 q) {
  q *= MUL.xy;
  uint n = (q.x ^ q.y) * MUL.x;
  return float(n) * INV;
}

float hash13(uvec3 q) {
  q *= MUL.xyz;
  uint n = (q.x ^ q.y ^ q.z) * MUL.x;
  return float(n) * INV;
}

float hash14(uvec4 q) {
  q *= MUL;
  uint n = (q.x ^ q.y ^ q.z ^ q.w) * MUL.x;
  return float(n) * INV;
}

float hash11(float p) {
  return hash11(uint(int(p)));
}

float hash12(vec2 p) {
  return hash12(uvec2(ivec2(p)));
}

float hash13(vec3 p) {
  return hash13(uvec3(ivec3(p)));
}

float hash14(vec4 p) {
  return hash14(uvec4(ivec4(p)));
}

// ---

vec2 hash21(uint q) {
  uvec2 n = q * MUL.xy;
  n = (n.x ^ n.y) * MUL.xy;
  return vec2(n) * INV;
}

vec2 hash22(uvec2 q) {
  q *= MUL.xy;
  q = (q.x ^ q.y) * MUL.xy;
  return vec2(q) * INV;
}

vec2 hash23(uvec3 q) {
  q *= MUL.xyz;
  uvec2 n = (q.x ^ q.y ^ q.z) * MUL.xy;
  return vec2(n) * INV;
}

vec2 hash21(float p) {
  return hash21(uint(int(p)));
}

vec2 hash22(vec2 p) {
  return hash22(uvec2(ivec2(p)));
}

vec2 hash23(vec3 p) {
  return hash23(uvec3(ivec3(p)));
}

// ---

vec3 hash31(uint q) {
  uvec3 n = q * MUL.xyz;
  n = (n.x ^ n.y ^ n.z) * MUL.xyz;
  return vec3(n) * INV;
}

vec3 hash32(uvec2 q) {
  uvec3 n = q.xyx * MUL.xyz;
  n = (n.x ^ n.y ^ n.z) * MUL.xyz;
  return vec3(n) * INV;
}

vec3 hash33(uvec3 q) {
  q *= MUL.xyz;
  q = (q.x ^ q.y ^ q.z) * MUL.xyz;
  return vec3(q) * INV;
}

vec3 hash31(float p) {
  return hash31(uint(int(p)));
}

vec3 hash32(vec2 q) {
  return hash32(uvec2(ivec2(q)));
}

vec3 hash33(vec3 p) {
  return hash33(uvec3(ivec3(p)));
}

// ---

vec4 hash44(uvec4 q) {
  q *= MUL;
  q = (q.x ^ q.y ^ q.z ^ q.w) * MUL;
  return vec4(q) * INV;
}

vec4 hash44(vec4 p) {
  return hash44(uvec4(ivec4(p)));
}

#undef MUL
#undef INV
