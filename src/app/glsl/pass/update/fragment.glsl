uniform sampler2D t_age;
uniform sampler2D t_position;
uniform sampler2D t_velocity;
uniform float u_t;
uniform float u_dt;
uniform float u_space_scale;
uniform float u_air_resistance;
uniform float u_flux_power;
uniform float u_flux_turbulence;
uniform ivec2 u_viewport;
uniform mat3 u_noise_rotation;
in vec2 v_uv;
out float f_age;
out vec2 f_position;
out vec2 f_velocity;

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

void Particle_respawn(inout Particle self, vec2 walls) {
  #if RESPAWN_MODE == 0 // same location
    vec2 p = hash22(uvec2(gl_FragCoord.xy));
  #elif RESPAWN_MODE == 1 // random location
    vec2 p = hash23(uvec3(gl_FragCoord.xy, 1e4 * fract(u_t)));
  #elif RESPAWN_MODE == 2 // screen edges
    vec3 h = hash33(uvec3(gl_FragCoord.xy, 1e4 * fract(u_t)));
    vec2 p = h.z < 0.5 ? vec2(h.x, round(h.y)) : vec2(round(h.x), h.y);
  #else
    #error invalid RESPAWN_MODE
  #endif

  self.pos = 2.0 * (p - 0.5) * walls;
  self.vel *= 0.0;
  self.age *= 0.0;
}

void Particle_respawnIfEscaped(inout Particle self, vec2 walls) {
  if (any(greaterThan(abs(self.pos), walls)))
    Particle_respawn(self, walls);
}

void Particle_bounce(inout Particle self, vec2 walls) {
  vec2 abs_pos = abs(self.pos);
  vec2 reverse = self.pos / abs_pos * (walls - abs_pos);
  bvec2 in_bounds = greaterThan(abs_pos, walls);
  self.pos = mix(self.pos, self.pos + reverse + reverse, in_bounds);
  self.vel = mix(self.vel, -self.vel, in_bounds);
}

void main() {
  float p_age = texture(t_age, v_uv).x;
  vec2 p_pos = texture(t_position, v_uv).xy;
  vec2 p_vel = texture(t_velocity, v_uv).xy;
  Particle p = Particle(p_age, p_pos, p_vel);

  const vec2 r = vec2(u_viewport) / float(u_viewport.y);
  vec3 fwd = vec3(1.0 / u_space_scale * p.pos * r, u_flux_turbulence * u_t + 5.0);
  vec3 rev = vec3(1.0, 1.0, -1.0) * fwd;
  float nx = simplex3d(u_noise_rotation * fwd);
  float ny = simplex3d(u_noise_rotation * rev);

  Particle_accelerate(p, u_dt, u_space_scale * u_flux_power / r * vec2(nx, ny));
  Particle_applyDrag(p, u_dt, u_air_resistance);
  Particle_travel(p, u_dt);

  #if WALLS_COLLISION
    Particle_bounce(p, vec2(1.0));
  #else
    Particle_respawnIfEscaped(p, vec2(1.0));
  #endif

  f_age = p.age;
  f_position = p.pos;
  f_velocity = p.vel;
}
