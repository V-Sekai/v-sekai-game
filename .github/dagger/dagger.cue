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
// install dagger-cue
// dagger-cue do build --cache-to type=local,mode=max,dest=.dagger_storage --cache-from type=local,mode=max,src=.dagger_storage --log-format plain

package main

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

godot: {
	core.#GitPull & {
		keepGitDir: true
		remote: "https://github.com/V-Sekai/godot.git"
		ref:    "groups-staging-4.x"
	}
}

godot_groups_modules: {
	core.#GitPull & {
		keepGitDir: true
		remote: "https://github.com/V-Sekai/godot-modules-groups"
		ref:    "main"
	}
}

fetch_godot: {
	docker.#Build & {
		steps: [
			docker.#Pull & {
				source: "rockylinux:8"
			},
			docker.#Set & {
				config: {
					user:    "root"
					workdir: "/"
					entrypoint: ["sh"]
				}
			},
			bash.#Run & {
				script: contents: #"""
					dnf install -y epel-release
					dnf config-manager --set-enabled powertools
					yum install unzip mingw32-binutils rsync gcc-toolset-9 gcc-toolset-9-libatomic-devel git-lfs automake autoconf libtool clang glibc-devel.i686 libgcc.i686 libstdc++.i686 python3-pip bash libX11-devel libXcursor-devel libXrandr-devel libXinerama-devel libXi-devel mesa-libGL-devel alsa-lib-devel pulseaudio-libs-devel freetype-devel openssl-devel libudev-devel mesa-libGLU-devel libpng-devel llvm-devel clang llvm-devel libxml2-devel libuuid-devel openssl-devel bash patch make git bzip2 xz xorg-x11-server-Xvfb pkgconfig mesa-dri-drivers ncurses-compat-libs unzip which gcc gcc-c++ libatomic -y
					"""#
			},
			bash.#Run & {
				script: contents: #"""
					yum group install -y "Development Tools"
					"""#
			},
			bash.#Run & {
				workdir: "/usr/local/bin"
				script: contents: #"""
					curl -L -o butler.zip https://broth.itch.ovh/butler/linux-amd64/LATEST/archive/default && unzip butler.zip && rm butler.zip && butler -V && butler -V && cd && butler -V
					"""#
			},
			bash.#Run & {
				workdir: "/v-sekai-game/godot"
				script: contents: #"""
					alternatives --set ld /usr/bin/ld.gold && git lfs install && pip3 install scons
					"""#
			},
			bash.#Run & {
				workdir: "/v-sekai-game/godot"
				script: contents: #"""
					mkdir /opt/llvm-mingw && curl -L https://github.com/mstorsjo/llvm-mingw/releases/download/20220906/llvm-mingw-20220906-ucrt-ubuntu-18.04-x86_64.tar.xz | tar -Jxf - --strip 1 -C /opt/llvm-mingw
					"""#
			},
			bash.#Run & {
				workdir: "/"
				script: contents: #"""
					adduser v-sekai-game
					"""#
			},
			docker.#Copy & {
				contents: godot_groups_modules.output
				dest:     "/v-sekai-game/godot_groups_modules"
			},
			docker.#Copy & {
				contents: godot.output
				dest:     "/v-sekai-game/godot"
			},
			bash.#Run & {
				workdir: "/"
				script: contents: #"""
					chown -R v-sekai-game /v-sekai-game
					"""#
			},
			bash.#Run & {
				workdir: "/v-sekai-game/godot"
				script: contents: #"""
					git submodule update --recursive --init
					"""#
			},
			bash.#Run & {
				workdir: "/v-sekai-game/godot_groups_modules"
				script: contents: #"""
					git submodule update --recursive --init
					"""#
			},
			docker.#Set & {
				config: {
					user:    "v-sekai-game"
					workdir: "/v-sekai-game"
					entrypoint: ["sh"]
				}
			},
			bash.#Run & {
				workdir: "/v-sekai-game/godot"
				script: contents: #"""
					"""#
				export:
					directories:
						"/v-sekai-game/godot": dagger.#FS
			},
		]
	}
}

dagger.#Plan & {
	client: {
		filesystem: 
			"../../": read: {
				contents: dagger.#FS,
				exclude: [".github/", ".godot/"]
			}
		filesystem:
            "../../build": write: {
				contents: actions.build.export.directories."/v-sekai-game/build"
            }
	}
	actions: {
		build:
			bash.#Run & {
				user: "root"
				mounts:
					"Local FS": {
						contents: client.filesystem."../../".read.contents
						dest:     "/v-sekai-game/project"
					}
				input:
					fetch_godot.output
				script: contents: #"""
					rm -rf /v-sekai-game/.local/share/godot/export_templates/
					rm -rf /v-sekai-game/project/.godot
					mkdir -p /v-sekai-game/project/build/ /v-sekai-game/project/build/.cicd_cache
					export VSK_CACHE=/v-sekai-game/project/build/.cicd_cache
					export VSK_GODOT_LINUX_BSD_X86_64=godot.linuxbsd.editor.x86_64.llvm
					export VSK_GODOT_WINDOWS_X86_64=godot.windows.editor.x86_64.llvm.exe
					###############
					# Export Linux.
					cd /v-sekai-game/godot
					SCONS_CACHE=$VSK_CACHE scons optimize=speed LINKFLAGS=-L/opt/rh/gcc-toolset-9/root/usr/lib/gcc/x86_64-redhat-linux/9/ werror=no platform=linuxbsd target=editor use_fastlto=no deprecated=no use_static_cpp=yes use_llvm=yes builtin_freetype=yes custom_modules=../godot_groups_modules					
					cp bin/$VSK_GODOT_LINUX_BSD_X86_64 bin/linux_debug.x86_64.llvm
					cp bin/$VSK_GODOT_LINUX_BSD_X86_64  bin/linux_editor.x86_64
					cp bin/$VSK_GODOT_LINUX_BSD_X86_64  bin/linux_release.x86_64.llvm && cp bin/$VSK_GODOT_LINUX_BSD_X86_64  bin/linux_release.x86_64 && strip --strip-debug bin/linux_release.x86_64
					cp bin/$VSK_GODOT_LINUX_BSD_X86_64  bin/linux_debug.x86_64.llvm && cp bin/$VSK_GODOT_LINUX_BSD_X86_64  bin/linux_debug.x86_64 && strip --strip-debug bin/linux_debug.x86_64	
					mkdir -p /v-sekai-game/.local/share/godot/export_templates/
					cd /v-sekai-game/.local/share/godot/export_templates/
					eval `sed -e "s/ = /=/" /v-sekai-game/godot/version.py` && echo $major.$minor.$status > /v-sekai-game/project/build/version.txt
					export VERSION=`cat /v-sekai-game/project/build/version.txt`
					export BASE_DIR=/v-sekai-game/.local/share/godot/export_templates/ 
					export TEMPLATEDIR=$BASE_DIR/$VERSION/
					mkdir -p $TEMPLATEDIR
					cp /v-sekai-game/godot/bin/linux_debug.x86_64 $TEMPLATEDIR/linux_debug.x86_64
					cp /v-sekai-game/godot/bin/linux_release.x86_64 $TEMPLATEDIR/linux_release.x86_64
					cp /v-sekai-game/project/build/version.txt $TEMPLATEDIR/version.txt
					if [[ -z "${REPO_NAME}" ]]; then
						export GODOT_ENGINE_GAME_NAME="v-sekai-game-"
					fi
					# TODO: build version
					# (echo \"## AUTOGENERATED BY BUILD\"; echo \"\"; echo \"const BUILD_LABEL = \\\"$GO_PIPELINE_LABEL\\\"\"; echo \"const BUILD_DATE_STR = \\\"$(date --utc --iso=seconds)\\\"\"; echo \"const BUILD_UNIX_TIME = $(date +%s)\" ) > /v-sekai-game/project/addons/vsk_version/build_constants.gd
					# End todo.
					cp /v-sekai-game/godot/bin/linux_release.x86_64 /v-sekai-game/project/build/linux_release.x86_64
					mkdir -p /v-sekai-game/project/build/linux_release_x86_64/
					mkdir -p /v-sekai-game/project/.godot/editor
					mkdir -p /v-sekai-game/project/.godot/imported && chmod +x /v-sekai-game/godot/bin/linux_editor.x86_64
					XDG_DATA_HOME=/v-sekai-game/.local/share/ /v-sekai-game/godot/bin/linux_editor.x86_64 --headless --export-release "Linux/X11" /v-sekai-game/project/build/linux_release_x86_64/${GODOT_ENGINE_GAME_NAME}linuxbsd --path /v-sekai-game/project || [ -f /v-sekai-game/project/build/linux_release_x86_64/${GODOT_ENGINE_GAME_NAME}linuxbsd ]
					#################
					# Export Windows.
					cd /v-sekai-game/godot
					SCONS_CACHE=$VSK_CACHE PATH=/opt/llvm-mingw/bin:$PATH scons optimize=speed werror=no platform=windows target=editor use_fastlto=no deprecated=no use_mingw=yes use_llvm=yes LINKFLAGS=-Wl,-pdb= CCFLAGS='-Wall -Wno-tautological-compare -g -gcodeview' debug_symbols=no custom_modules=../godot_groups_modules
					cp bin/$VSK_GODOT_WINDOWS_X86_64 bin/windows_release_x86_64.exe 
					mingw-strip --strip-debug bin/windows_release_x86_64.exe
					cp bin/godot.windows.editor.x86_64.llvm.pdb bin/windows_release_x86_64.pdb
					mkdir -p /v-sekai-game/project/build/
					mkdir -p /v-sekai-game/.local/share/godot/export_templates/
					cd /v-sekai-game/.local/share/godot/export_templates/
					eval `sed -e "s/ = /=/" /v-sekai-game/godot/version.py` && echo $major.$minor.$status > /v-sekai-game/project/build/version.txt
					export VERSION=`cat /v-sekai-game/project/build/version.txt`
					export BASE_DIR=/v-sekai-game/.local/share/godot/export_templates/ 
					export TEMPLATEDIR=$BASE_DIR/$VERSION/
					mkdir -p $TEMPLATEDIR
					cp /v-sekai-game/godot/bin/windows_release_x86_64.exe $TEMPLATEDIR/windows_release_x86_64.exe
					cp /v-sekai-game/godot/bin/windows_release_x86_64.exe $TEMPLATEDIR/windows_debug_x86_64.exe
					cp /v-sekai-game/project/build/version.txt $TEMPLATEDIR/version.txt
					if [[ -z "${REPO_NAME}" ]]; then
						export GODOT_ENGINE_GAME_NAME="v-sekai-game-"
					fi
					# TODO: build version
					# (echo \"## AUTOGENERATED BY BUILD\"; echo \"\"; echo \"const BUILD_LABEL = \\\"$GO_PIPELINE_LABEL\\\"\"; echo \"const BUILD_DATE_STR = \\\"$(date --utc --iso=seconds)\\\"\"; echo \"const BUILD_UNIX_TIME = $(date +%s)\" ) > /v-sekai-game/project/addons/vsk_version/build_constants.gd
					# End todo.
					cp /v-sekai-game/godot/bin/windows_release_x86_64.exe /v-sekai-game/project/build/windows_release_x86_64.exe
					cp /v-sekai-game/godot/bin/windows_release_x86_64.pdb /v-sekai-game/project/build/windows_release_x86_64.pdb
					mkdir -p /v-sekai-game/project/build/windows_release_x86_64/ && mkdir -p /v-sekai-game/project/.godot/editor
					mkdir -p /v-sekai-game/project/.godot/imported && chmod +x /v-sekai-game/godot/bin/linux_editor.x86_64
					XDG_DATA_HOME=/v-sekai-game/.local/share/ /v-sekai-game/godot/bin/linux_editor.x86_64 --headless --export-release "Windows Desktop" /v-sekai-game/project/build/windows_release_x86_64/${GODOT_ENGINE_GAME_NAME}windows.exe --path /v-sekai-game/project || [ -f /v-sekai-game/project/build/windows_release_x86_64/${GODOT_ENGINE_GAME_NAME}windows.exe ]
					cp /v-sekai-game/godot/bin/windows_release_x86_64.pdb /v-sekai-game/project/build/windows_release_x86_64/${GODOT_ENGINE_GAME_NAME}windows.pdb
					######################################
					# Move build artifacts to be exported.
					cp -rf /v-sekai-game/project/build /v-sekai-game/build
					touch /v-sekai-game/build/.gdignore
					ls /v-sekai-game/build
					"""#
				export:
					directories:
						"/v-sekai-game/build": dagger.#FS
			}
	}
}