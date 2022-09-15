time_scale: f32 = 1.0,
space_scale: f32 = 0.5,
air_resistance: f32 = 0.65,
wind_power: f32 = 0.25,
wind_turbulence: f32 = 0.05,
walls_collision: bool = false,

feedback_ratio: f32 = 0.35,
brightness: f32 = 0.75,
aces_tonemapping: bool = true,

steps_per_frame: c_int = 4,
simulation_size: [2]c_int = .{ 512, 512 },
