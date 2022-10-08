// MIT License

// Copyright (c) 2022 K. S. Ernest (iFire) Lee

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// # How to use?
// scoop install rancher-desktop
// Enable moby mode
// scoop install dagger
// dagger do build

package main

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

godot: {
	core.#GitPull & {
		remote: "https://github.com/V-Sekai/godot.git"
		ref:    "groups-4.x.2022-10-01T091343Z" // Use tags and not floating branches.
	}
}
godot_groups_modules: {
	core.#GitPull & {
		remote: "https://github.com/V-Sekai/godot-modules-groups"
		ref:    "bcc46365643767e1a2ea2fadf73d19da7078e5af" // Use tags and not floating branches.
	}
}

fetch_godot: {
	docker.#Build & {
		steps: [
			docker.#Pull & {
				source: "fedora:35"
			},
			docker.#Set & {
				config: {
					user:    "root"
					workdir: "/"
					entrypoint: ["sh"]
				}
			},
			bash.#Run & {
				workdir: "/groups/godot"
				script: contents: #"""
					yum install unzip -y
					"""#
			},
			bash.#Run & {
				workdir: "/groups/godot"
				script: contents: #"""
					cd /usr/local/bin && curl -L -o butler.zip https://broth.itch.ovh/butler/linux-amd64/LATEST/archive/default && unzip butler.zip && rm butler.zip && butler -V && butler -V && cd && butler -V
					"""#
			},
			bash.#Run & {
				workdir: "/groups/godot"
				script: contents: #"""
					yum group install -y "Development Tools"
					"""#
			},
			bash.#Run & {
				workdir: "/groups/godot"
				script: contents: #"""
					yum install -y git-lfs automake autoconf libtool yasm cmake python3-scons clang glibc-devel.i686 libgcc.i686 libstdc++.i686 mingw64-gcc-c++ mingw32-gcc mingw32-gcc-c++ python3-pip mingw64-winpthreads mingw32-winpthreads mingw64-winpthreads-static mingw32-winpthreads-static libstdc++-static mingw64-filesystem mingw32-filesystem bash libX11-devel libXcursor-devel libXrandr-devel libXinerama-devel libXi-devel mesa-libGL-devel alsa-lib-devel pulseaudio-libs-devel freetype-devel openssl-devel libudev-devel mesa-libGLU-devel libpng-devel xar-devel llvm-devel clang llvm-devel libxml2-devel libuuid-devel openssl-devel bash patch libstdc++-static make git bzip2 xz java-openjdk yasm xorg-x11-server-Xvfb pkgconfig mesa-dri-drivers java-1.8.0-openjdk-devel ncurses-compat-libs unzip which gcc gcc-c++ libatomic-static libatomic ccache ninja-build
					"""#
			},
			bash.#Run & {
				workdir: "/groups/godot"
				script: contents: #"""
					alternatives --set ld /usr/bin/ld.gold && git lfs install && ln -s /usr/bin/scons-3 /usr/local/bin/scons
					"""#
			},
			bash.#Run & {
				workdir: "/groups/godot"
				script: contents: #"""
					mkdir /opt/llvm-mingw && curl -L https://github.com/mstorsjo/llvm-mingw/releases/download/20220323/llvm-mingw-20220323-ucrt-ubuntu-18.04-x86_64.tar.xz | tar -Jxf - --strip 1 -C /opt/llvm-mingw
					"""#
			},
			bash.#Run & {
				workdir: "/"
				script: contents: #"""
					adduser groups
					"""#
			},
			docker.#Copy & {
				contents: godot_groups_modules.output
				dest:     "/groups/godot_groups_modules"
			},
			docker.#Copy & {
				contents: godot.output
				dest:     "/groups/godot"
			},
			bash.#Run & {
				workdir: "/"
				script: contents: #"""
					chown -R groups /groups
					"""#
			},
			docker.#Set & {
				config: {
					user:    "groups"
					workdir: "/groups"
					entrypoint: ["sh"]
				}
			},
		]
	}
}

build_godot_windows:
	bash.#Run & {
		input:   fetch_godot.output
		workdir: "/groups/godot"
		script: contents: #"""
			PATH=/opt/llvm-mingw/bin:$PATH scons float=64 werror=no platform=windows target=editor use_lto=no deprecated=no use_mingw=yes use_llvm=yes use_thinlto=no warnings=no LINKFLAGS=-Wl,-pdb= CCFLAGS='-Wall -Wno-tautological-compare -g -gcodeview' debug_symbols=no custom_modules=../godot_groups_modules
			"""#
		export:
			directories:
				"/groups/godot/bin": dagger.#FS
	}
build_godot_linux:
	bash.#Run & {
		input:   build_godot_windows.output
		workdir: "/groups/godot"
		script: contents: #"""
			PATH=/opt/llvm-mingw/bin:$PATH scons float=64 werror=no platform=linuxbsd target=editor use_lto=no deprecated=no use_static_cpp=yes use_llvm=yes builtin_freetype=yes custom_modules=../godot_groups_modules
			"""#
		export:
			directories:
				"/groups/godot/bin": dagger.#FS
	}
build_godot:
	bash.#Run & {
		input:   build_godot_linux.output
		workdir: "/groups/godot"
		script: contents: #"""
			ls /groups/godot/bin
			"""#
		export:
			directories:
				"/groups/godot/bin": dagger.#FS
	}

dagger.#Plan & {
	client: {
		filesystem: "../../": 
			read: {
				contents: dagger.#FS,
        		exclude: [".github/", ".godot/"]
			}
		filesystem: {
			"../../build": write: contents: actions.build.export.directories."/groups/build"
		}
	}
	actions: {
		build:
			bash.#Run & {
				user: "root"
				mounts:
					"Local FS": {
						contents: client.filesystem."../../".read.contents
						dest:     "/groups/project"
					}
				input:
					build_godot.output
				script: contents: #"""
					cd /groups/godot
					cp bin/godot.windows.editor.double.x86_64.llvm.exe bin/windows_release_x86_64.exe 
					mingw-strip --strip-debug bin/windows_release_x86_64.exe
					cp bin/godot.windows.editor.double.x86_64.llvm.pdb bin/windows_release_x86_64.pdb
					cp bin/godot.linuxbsd.editor.double.x86_64.llvm bin/linux_debug.x86_64.llvm
					cp bin/godot.linuxbsd.editor.double.x86_64.llvm bin/linux_editor.x86_64
					# Export the game.
					cp bin/godot.linuxbsd.editor.double.x86_64.llvm bin/linux_release.x86_64.llvm && cp bin/godot.linuxbsd.editor.double.x86_64.llvm bin/linux_release.x86_64 && strip --strip-debug bin/linux_release.x86_64
					cp bin/godot.linuxbsd.editor.double.x86_64.llvm bin/linux_debug.x86_64.llvm && cp bin/godot.linuxbsd.editor.double.x86_64.llvm bin/linux_debug.x86_64 && strip --strip-debug bin/linux_debug.x86_64	
					rm -rf /groups/project/build
					mkdir -p /groups/build/
					rm -rf /groups/.local/share/godot/export_templates/
					mkdir -p /groups/.local/share/godot/export_templates/
					cd /groups/.local/share/godot/export_templates/
					eval `sed -e "s/ = /=/" /groups/godot/version.py` && echo $major.$minor.$status > /groups/build/version.txt
					export VERSION=`cat /groups/build/version.txt`
					export BASE_DIR=/groups/.local/share/godot/export_templates/ 
					export TEMPLATEDIR=$BASE_DIR/$VERSION/
					mkdir -p $TEMPLATEDIR
					cp /groups/godot/bin/windows_release_x86_64.exe $TEMPLATEDIR/windows_release_x86_64.exe
					cp /groups/godot/bin/windows_release_x86_64.exe $TEMPLATEDIR/windows_debug_x86_64.exe
					cp /groups/godot/bin/linux_debug.x86_64 $TEMPLATEDIR/linux_debug.x86_64
					cp /groups/godot/bin/linux_release.x86_64 $TEMPLATEDIR/linux_release.x86_64
					cp /groups/build/version.txt $TEMPLATEDIR/version.txt
					if [[ -z "${REPO_NAME}" ]]; then
						export GODOT_ENGINE_GAME_NAME="game_"
					fi
					# TODO: build version
					# (echo \"## AUTOGENERATED BY BUILD\"; echo \"\"; echo \"const BUILD_LABEL = \\\"$GO_PIPELINE_LABEL\\\"\"; echo \"const BUILD_DATE_STR = \\\"$(date --utc --iso=seconds)\\\"\"; echo \"const BUILD_UNIX_TIME = $(date +%s)\" ) > /groups/project/addons/vsk_version/build_constants.gd
					# End todo.
					mkdir -p /groups/project/.godot/editor && mkdir -p /groups/project/.godot/imported && chmod +x /groups/godot/bin/linux_editor.x86_64 && XDG_DATA_HOME=/groups/.local/share/ /groups/godot/bin/linux_editor.x86_64 --headless --export "Windows Desktop" /groups/build/${GODOT_ENGINE_GAME_NAME}windows.exe --path /groups/project && [ -f /groups/build/${GODOT_ENGINE_GAME_NAME}windows.exe ]
					mkdir -p /groups/project/.godot/editor && mkdir -p /groups/project/.godot/imported && chmod +x /groups/godot/bin/linux_editor.x86_64 && XDG_DATA_HOME=/groups/.local/share/ /groups/godot/bin/linux_editor.x86_64 --headless --export "Linux/X11" /groups/build/${GODOT_ENGINE_GAME_NAME}linuxbsd --path /groups/project && [ -f /groups/build/${GODOT_ENGINE_GAME_NAME}linuxbsd ]
					cp /groups/godot/bin/windows_release_x86_64.pdb /groups/build/${GODOT_ENGINE_GAME_NAME}windows.pdb
					echo ok
					"""#
				export:
					directories:
						"/groups/build": dagger.#FS
			}
	}
}
