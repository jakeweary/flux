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

void Particle_applyDrag(inout Particle self, in float dt, in float drag) {
  self.vel *= exp(dt * log(drag));
}

void Particle_accelerate(inout Particle self, in float dt, in vec2 acc) {
  self.vel += dt * acc;
}

void Particle_travel(inout Particle self, in float dt) {
  self.pos += dt * self.vel;
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
  float p_size = texture(tSize, vUV).x;
  vec2 p_pos = texture(tPosition, vUV).xy;
  vec2 p_vel = texture(tVelocity, vUV).xy;
  Particle p = Particle(p_size, p_pos, p_vel);

  const vec2 ar = vec2(16.0 / 9.0, 1.0);
  vec3 xyz = vec3(0.5 * p.pos * ar, 100.0 + 0.05 * uT);
  float nx = simplex3d_fractal(xyz);
  float ny = simplex3d_fractal(xyz * vec3(1.0, 1.0, -1.0));

  Particle_accelerate(p, uDT, 10.0 / ar / p.size * vec2(nx, ny));
  Particle_applyDrag(p, uDT, 0.3);
  Particle_travel(p, uDT);
  Particle_resetIfEscaped(p, vec2(1.0));
  // Particle_bounce(p, vec2(1.0));

  fVelocity = p.vel;
  fPosition = p.pos;
}
