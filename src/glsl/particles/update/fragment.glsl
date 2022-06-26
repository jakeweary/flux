uniform sampler2D tSize;
uniform sampler2D tPosition;
uniform sampler2D tVelocity;
uniform float uT;
uniform float uDT;
in vec2 vUV;
out vec2 fPosition;
out vec2 fVelocity;

struct Particle {
  float size;
  vec2 pos, vel;
};

void Particle_applyDrag(inout Particle self, in float drag) {
  self.vel *= drag;
}

void Particle_accelerate(inout Particle self, in vec2 acc) {
  self.vel += acc;
}

void Particle_travel(inout Particle self) {
  self.pos += self.vel;
}

void Particle_reset(inout Particle self, in vec2 walls) {
  self.pos = 2.0 * (hash22(1e3 * vUV) - 0.5) * walls;
  self.vel = vec2(0.0);
}

void Particle_resetIfEscaped(inout Particle self, in vec2 walls) {
  if (any(greaterThan(abs(self.pos), walls)))
    Particle_reset(self, walls);
}

void Particle_bounce(inout Particle self, in vec2 walls) {
  vec2 abs_pos = abs(self.pos);
  vec2 reverse = self.pos / abs_pos * (walls - abs_pos);
  bvec2 in_bounds = greaterThan(abs_pos, walls);
  self.pos = mix(self.pos, self.pos + reverse + reverse, in_bounds);
  self.vel = mix(self.vel, -self.vel, in_bounds);
}

void main() {
  float ps = texture(tSize, vUV).x;
  vec2 pp = texture(tPosition, vUV).xy;
  vec2 pv = texture(tVelocity, vUV).xy;
  Particle p = Particle(ps, pp, pv);

  const vec2 ar = vec2(16.0 / 9.0, 1.0);
  vec3 xyz = vec3(0.5 * p.pos * ar, 100.0 + 0.05 * uT);
  float nx = simplex3d_fractal(xyz);
  float ny = simplex3d_fractal(xyz * vec3(1.0, 1.0, -1.0));

  Particle_accelerate(p, uDT * vec2(nx, ny) / ar / p.size);
  Particle_applyDrag(p, exp(uDT * log(0.01)));
  Particle_travel(p);
  Particle_resetIfEscaped(p, vec2(1.0));

  fVelocity = p.vel;
  fPosition = p.pos;
}
