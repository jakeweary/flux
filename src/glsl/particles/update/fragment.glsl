uniform sampler2D tSize;
uniform sampler2D tPosition;
uniform sampler2D tVelocity;
uniform float uT;
uniform float uDT;
in vec2 vUV;
out vec2 position;
out vec2 velocity;

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

void Particle_bounce(inout Particle self, in vec2 walls) {
  vec2 abs_pos = abs(self.pos);
  vec2 reverse = self.pos / abs_pos * (walls - abs_pos);
  bvec2 in_bounds = greaterThan(abs_pos, walls);
  self.pos = mix(self.pos, self.pos + reverse + reverse, in_bounds);
  self.vel = mix(self.vel, -self.vel, in_bounds);
}

void Particle_resetIfEscaped(inout Particle self, in vec2 walls) {
  if (any(greaterThan(abs(self.pos), walls))) {
    self.pos = 2.0 * hash22(1e3 * self.pos) - 1.0;
    self.vel = vec2(0.0);
  }
}

void main() {
  float size = texture(tSize, vUV).x;
  vec2 pos = texture(tPosition, vUV).xy;
  vec2 vel = texture(tVelocity, vUV).xy;
  Particle p = Particle(size, pos, vel);

  const vec2 ar = vec2(16.0 / 9.0, 1.0);
  vec3 xyz = vec3(p.pos * ar, 1e2 + 5e-2 * uT);
  vec2 noise = vec2(simplex3d(xyz), simplex3d(xyz * vec3(1, 1, -1)));
  Particle_accelerate(p, uDT * 3e-1 * noise / ar / p.size);
  Particle_applyDrag(p, exp(uDT * log(0.3)));
  Particle_travel(p);
  Particle_resetIfEscaped(p, vec2(1.0));

  velocity = p.vel;
  position = p.pos;
}
