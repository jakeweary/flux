```
$ zig version
0.11.0-dev.1011+40ba4d4a8
```
```sh
# build and run:
zig build run

# build in release mode:
zig build -Doptimize=ReleaseFast

# dependencies to build/run on linux:
apt install libglfw3 libglfw3-dev
```
```sh
# upgrade Glad:
url=$(curl -Lo /dev/null -w %{url_effective} https://gen.glad.sh/generate \
  -d 'generator=c&api=gl%3D4.6&profile=gl%3Dcore&options=HEADER_ONLY')
curl -o deps/include/glad/gl.h ${url}include/glad/gl.h

# upgrade GLFW:
url=$(curl -Lo /dev/null -w %{url_effective} https://github.com/glfw/glfw/releases/latest)
curl -LO ${url/tag/download}/glfw-${url##*/}.bin.WIN64.zip
unzip -q glfw-*.zip
cp -r glfw-*/include/GLFW/ deps/include/
cp glfw-*/lib-mingw-w64/libglfw3.a deps/lib/glfw.lib
rm -rf glfw-*

# upgrade Dear ImGui:
git clone --recursive https://github.com/cimgui/cimgui
cp cimgui/{*.{h,cpp},generator/output/cimgui_impl.h} deps/include/cimgui/
cp cimgui/imgui/{*.{h,cpp},backends/imgui_impl_{glfw,opengl3}.*} deps/include/cimgui/imgui/
rm -rf cimgui
```
