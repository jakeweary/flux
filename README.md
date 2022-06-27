```sh
# build and run:
zig build run

# build in release mode:
zig build -Drelease-fast

# cross-compile for windows:
zig build -Drelease-fast -Dtarget=x86_64-windows-gnu

# dependencies to build/run on linux:
apt install libglfw3 libglfw3-dev
```
