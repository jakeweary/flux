SHELL = bash

.PHONY = update-all update-glad update-glfw update-imgui update-stb
update-all: update-glad update-glfw update-imgui update-stb

update-glad:
	url=$$(curl -Lo /dev/null -w %{url_effective} https://gen.glad.sh/generate \
		-d 'generator=c&api=gl%3D4.6&profile=gl%3Dcore&options=HEADER_ONLY'); \
	curl -o deps/include/glad/gl.h $${url}include/glad/gl.h

update-glfw:
	url=$$(curl -Lo /dev/null -w %{url_effective} https://github.com/glfw/glfw/releases/latest); \
	curl -LO $${url/tag/download}/glfw-$${url##*/}.bin.WIN64.zip
	unzip -q glfw-*.zip
	cp -r glfw-*/include/GLFW/ deps/include/
	cp glfw-*/lib-mingw-w64/libglfw3.a deps/lib/glfw.lib
	rm -rf glfw-*

update-imgui:
	git clone --recursive https://github.com/cimgui/cimgui
	mkdir -p deps/include/cimgui/imgui/
	cp cimgui/{*.{h,cpp},generator/output/cimgui_impl.h} deps/include/cimgui/
	cp cimgui/imgui/{*.{h,cpp},backends/imgui_impl_{glfw,opengl3}.*} deps/include/cimgui/imgui/
	rm -rf cimgui

update-stb:
	for file in stb_image{,_write}.h; do \
		curl -o deps/include/$$file https://raw.githubusercontent.com/nothings/stb/master/$$file; \
	done
