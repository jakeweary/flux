uniform sampler2D t_age;
uniform sampler2D t_position;
uniform sampler2D t_velocity;
uniform float u_t;
uniform float u_dt;
uniform float u_space_scale;
uniform float u_air_resistance;
uniform float u_flux_power;
uniform float u_flux_turbulence;
uniform float u_respawn_velocity;
uniform vec3 u_lifespan; // 1/λ, μ, σ
uniform mat3 u_noise_rotation;
uniform ivec2 u_viewport;
uniform uvec3 u_random;
in vec2 v_uv;
out vec2 f_age;
out vec2 f_position;
out vec2 f_velocity;

#define BOUNDS vec2(1)

// https://en.wikipedia.org/wiki/Box-Muller_transform
vec2 normal(vec2 random) {
  float r = sqrt(-2.0 * log(1.0 - random.x));
  float theta = radians(360.0) * random.y;
  return r * vec2(sin(theta), cos(theta));
}

struct Particle {
  float age, lifespan;
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

void Particle_respawn(inout Particle self) {
  #if LIFESPAN_MODE == 0 // infinite lifespan
    float a = 0.0;
  #elif LIFESPAN_MODE == 1 // exponential distribution
    float a = -log(1.0 - hash13(uvec3(gl_FragCoord.xy, u_random.x)));
  #elif LIFESPAN_MODE == 2 // normal distribution
    float a = normal(hash23(uvec3(gl_FragCoord.xy, u_random.x))).x;
  #else
    #error invalid LIFESPAN_MODE
  #endif

  #if RESPAWN_MODE == 0 // same location
    vec2 p = hash22(uvec2(gl_FragCoord.xy));
  #elif RESPAWN_MODE == 1 // random location
    vec2 p = hash23(uvec3(gl_FragCoord.xy, u_random.y));
  #elif RESPAWN_MODE == 2 // screen edges
    vec3 h = hash33(uvec3(gl_FragCoord.xy, u_random.y));
    vec2 p = h.z < 0.5 ? vec2(h.x, round(h.y)) : vec2(round(h.x), h.y);
  #elif RESPAWN_MODE == 3 // screen center
    vec2 p = vec2(0.5);
  #else
    #error invalid RESPAWN_MODE
  #endif

  vec2 v = normal(hash23(uvec3(gl_FragCoord.xy, u_random.z)));

  self.lifespan = a;
  self.age = 0.0;
  self.pos = 2.0 * (p - 0.5) * BOUNDS;
  self.vel = u_respawn_velocity * v;
}

void Particle_respawnIfEscaped(inout Particle self) {
  if (any(greaterThan(abs(self.pos), BOUNDS)))
    Particle_respawn(self);
}

void Particle_respawnIfTooOld(inout Particle self) {
  #if LIFESPAN_MODE == 0 // no aging
    // noop
  #elif LIFESPAN_MODE == 1 // geometric distribution
    if (self.age >= u_lifespan.x * self.lifespan)
      Particle_respawn(self);
  #elif LIFESPAN_MODE == 2 // normal distribution
    if (self.age >= u_lifespan.y + u_lifespan.z * self.lifespan)
      Particle_respawn(self);
  #else
    #error invalid LIFESPAN_MODE
  #endif
}

void Particle_bounce(inout Particle self) {
  vec2 abs_pos = abs(self.pos);
  vec2 reverse = self.pos / abs_pos * (BOUNDS - abs_pos);
  bvec2 in_bounds = greaterThan(abs_pos, BOUNDS);
  self.pos = mix(self.pos, self.pos + reverse + reverse, in_bounds);
  self.vel = mix(self.vel, -self.vel, in_bounds);
}

void main() {
  vec2 p_age = texture(t_age, v_uv).xy;
  vec2 p_pos = texture(t_position, v_uv).xy;
  vec2 p_vel = texture(t_velocity, v_uv).xy;
  Particle p = Particle(p_age.x, p_age.y, p_pos, p_vel);

  const vec2 r = vec2(u_viewport) / float(u_viewport.y);
  vec3 fwd = vec3(1.0 / u_space_scale * p.pos * r, u_flux_turbulence * u_t + 5.0);
  vec3 rev = vec3(1.0, 1.0, -1.0) * fwd;
  float nx = simplex3d(u_noise_rotation * fwd);
  float ny = simplex3d(u_noise_rotation * rev);

  Particle_accelerate(p, u_dt, u_space_scale * u_flux_power / r * vec2(nx, ny));
  Particle_applyDrag(p, u_dt, u_air_resistance);
  Particle_travel(p, u_dt);

  #if SCREEN_EDGES_COLLISION
    Particle_bounce(p);
  #else
    Particle_respawnIfEscaped(p);
  #endif

  #if LIFESPAN_MODE
    Particle_respawnIfTooOld(p);
  #endif

  f_age = vec2(p.age, p.lifespan);
  f_position = p.pos;
  f_velocity = p.vel;
}
