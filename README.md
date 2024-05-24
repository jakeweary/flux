# Flux

![screenshot](https://i.imgur.com/djHNw0P.png)

A real-time GPU-accelerated particle sandbox. Designed a way so there's no processing done on the CPU. All particles are stored in a few float32 textures, updated and rendered using a bunch of fancy shaders. So it's blazingly fast! Simulating a few million particles at 60 FPS is a boring task even for my ancient GPU, a modern one will likely handle tens of millions.

## Features

- As [GPGPU][1] as it gets: no work on the CPU and no data transfers from/to the main memory
- Fancy post-processing: high quality multi-pass [bloom filter][2], [ACES][3] [tonemapping][4], etc.
- Perceptually uniform color spaces: [CIELAB][5], [CIELUV][6], [Oklab][7], etc.
- Lots of simulation and rendering settings to mess around with

[1]: https://en.wikipedia.org/wiki/GPGPU
[2]: https://youtu.be/ml-5OGZC7vE
[3]: https://chrisbrejon.com/cg-cinematography/chapter-1-5-academy-color-encoding-system-aces/
[4]: https://en.wikipedia.org/wiki/Tone_mapping
[5]: https://en.wikipedia.org/wiki/CIELAB
[6]: https://en.wikipedia.org/wiki/CIELUV
[7]: https://bottosson.github.io/posts/oklab/

## Instructions

**NOTE:** must be compiled with [Zig][8] 0.12, tested only on Windows and WSL2

[8]: https://ziglang.org/

```sh
# build and run:
zig build run

# build in release mode:
zig build --release

# dependencies to build/run on linux:
apt install libglfw3 libglfw3-dev
```

## Made with
- https://github.com/ziglang/zig
- https://github.com/Dav1dde/glad
- https://github.com/glfw/glfw
- https://github.com/ocornut/imgui
- https://github.com/cimgui/cimgui
- https://github.com/nothings/stb

## Useful resources
- https://docs.gl/
- https://open.gl/
- https://learnopengl.com/
- https://khronos.org/opengl/wiki/
- https://github.com/fendevel/Guide-to-Modern-OpenGL-Functions
