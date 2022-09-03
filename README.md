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
```sh
# get/update imgui
git clone --recurse-submodules https://github.com/cimgui/cimgui
rm -rf deps/cimgui && mkdir -p deps/cimgui/imgui
cp cimgui/{*.{h,cpp},generator/output/cimgui_impl.h} deps/cimgui
cp cimgui/imgui/{*.{h,cpp},backends/imgui_impl_{glfw,opengl3}.*} deps/cimgui/imgui
rm -rf cimgui
```
```
$ zig version
0.10.0-dev.3841+7c91a6fe4
```
