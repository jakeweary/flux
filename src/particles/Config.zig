// scaling
time_scale: f32 = 0.8,
space_scale: f32 = 0.5,

// simulation
air_resistance: f32 = 0.65,
wind_power: f32 = 0.25,
wind_turbulence: f32 = 0.05,

// rendering
point_scale: f32 = 1.0,
feedback_loop: f32 = 0.3,

// post-processing
brightness: f32 = 2.0,

// performance
steps_per_frame: c_int = 1,
simulation_size: [2]c_int = .{ 512, 512 },
vsync: bool = true,
