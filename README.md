```sh
# build and run:
zig build run -fstage1

# build in release mode:
zig build -fstage1 -Drelease-fast

# cross-compile for windows:
zig build -fstage1 -Drelease-fast -Dtarget=x86_64-windows-gnu

# dependencies to build/run on linux:
apt install libglfw3 libglfw3-dev
```
```
$ zig version
0.10.0-dev.3685+dae7aeb33
```
