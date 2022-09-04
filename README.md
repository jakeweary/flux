```sh
# build and run:
zig build run

# build in release mode:
zig build -Drelease-fast

# dependencies to build/run on linux:
apt install libglfw3 libglfw3-dev
```
```
$ zig version
0.10.0-dev.3841+7c91a6fe4
```
```sh
# upgrade Dear ImGui:
git clone --recurse-submodules https://github.com/cimgui/cimgui
cp cimgui/{*.{h,cpp},generator/output/cimgui_impl.h} deps/include/cimgui/
cp cimgui/imgui/{*.{h,cpp},backends/imgui_impl_{glfw,opengl3}.*} deps/include/cimgui/imgui/
rm -rf cimgui
```
```sh
# upgrade GLFW:
url=$(curl -Lso /dev/null -w %{url_effective} https://github.com/glfw/glfw/releases/latest)
curl -LO ${url/tag/download}/glfw-${url##*/}.bin.WIN64.zip
unzip -q glfw-*.zip
cp -r glfw-*/include/GLFW/ deps/include/
cp glfw-*/lib-mingw-w64/libglfw3.a deps/lib/glfw.lib
rm -rf glfw-*
```
