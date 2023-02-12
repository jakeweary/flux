uniform sampler2D tAge;
uniform sampler2D tPosition;
uniform sampler2D tVelocity;
uniform float uT;
uniform float uDT;
uniform float uSpaceScale;
uniform float uAirResistance;
uniform float uFluxPower;
uniform float uFluxTurbulence;
uniform ivec2 uViewport;
uniform mat3 uNoiseRotation;
in vec2 vUV;
out float fAge;
out vec2 fPosition;
out vec2 fVelocity;

struct Particle {
  float age;
  vec2 pos, vel;
};

void Particle_applyDrag(inout Particle self, float dt, float drag) {
  self.vel *= exp(dt * log(drag));
}

void Particle_accelerate(inout Particle self, float dt, vec2 acc) {
  self.vel += dt * acc;
}

void Particle_travel(inout Particle self, float dt) {
  self.pos += dt * self.vel;
  self.age += dt;
}

void Particle_reset(inout Particle self, vec2 walls) {
  self.pos = 2.0 * (hash22(1e3 * vUV) - 0.5) * walls;
  self.vel *= 0.0;
  self.age *= 0.0;
}

void Particle_resetIfEscaped(inout Particle self, vec2 walls) {
  if (any(greaterThan(abs(self.pos), walls)))
    Particle_reset(self, walls);
}

void Particle_bounce(inout Particle self, vec2 walls) {
  vec2 abs_pos = abs(self.pos);
  vec2 reverse = self.pos / abs_pos * (walls - abs_pos);
  bvec2 in_bounds = greaterThan(abs_pos, walls);
  self.pos = mix(self.pos, self.pos + reverse + reverse, in_bounds);
  self.vel = mix(self.vel, -self.vel, in_bounds);
}

void main() {
  float pAge = texture(tAge, vUV).x;
  vec2 pPos = texture(tPosition, vUV).xy;
  vec2 pVel = texture(tVelocity, vUV).xy;
  Particle p = Particle(pAge, pPos, pVel);

  const vec2 r = vec2(uViewport) / float(uViewport.y);
  vec3 fwd = vec3(1.0 / uSpaceScale * p.pos * r, uFluxTurbulence * uT + 5.0);
  vec3 rev = vec3(1.0, 1.0, -1.0) * fwd;
  float nx = simplex3d(uNoiseRotation * fwd);
  float ny = simplex3d(uNoiseRotation * rev);

  Particle_accelerate(p, uDT, uSpaceScale * uFluxPower / r * vec2(nx, ny));
  Particle_applyDrag(p, uDT, uAirResistance);
  Particle_travel(p, uDT);

  #if WALLS_COLLISION
    Particle_bounce(p, vec2(1.0));
  #else
    Particle_resetIfEscaped(p, vec2(1.0));
  #endif

  fAge = p.age;
  fPosition = p.pos;
  fVelocity = p.vel;
}
