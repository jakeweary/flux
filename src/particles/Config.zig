time_scale: f32 = 0.8,
space_scale: f32 = 0.5,
air_resistance: f32 = 0.65,
wind_power: f32 = 0.25,
wind_turbulence: f32 = 0.05,
walls_collision: bool = false,

feedback_loop: f32 = 0.3,
render_as_lines: bool = true,
dynamic_line_brightness: bool = true,

brightness: f32 = 4.0,
aces_tonemapping: bool = true,

steps_per_frame: c_int = 1,
simulation_size: [2]c_int = .{ 512, 512 },
vsync: bool = true,
