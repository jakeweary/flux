noise_rotation: [3][3]f32 = .{
  .{ 1, 0, 0 },
  .{ 0, 1, 0 },
  .{ 0, 0, 1 },
},

// simulation
time_scale: f32 = 0.5,
space_scale: f32 = 0.5,
air_resistance: f32 = 0.65,
flux_power: f32 = 0.25,
flux_turbulence: f32 = 0.05,

// rendering
point_scale: f32 = 1.0,
smooth_spawn: f32 = 0.15,
feedback: f32 = 0.25,

// post-processing
brightness: f32 = 5.0,
bloom: f32 = 0.5,

// performance
simulation_size: [2]c_int = .{ 512, 512 },
steps_per_frame: c_int = 1,
bloom_levels: c_int = 9,
vsync: bool = true,

// debug
bloom_level: c_int = 0,
bloom_texture: c_int = 0,
