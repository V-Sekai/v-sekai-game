#!/usr/bin/env bash

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

git clone https://github.com/V-Sekai/godot.git $SCRIPTPATH/../../godot -b groups-4.x
git clone https://github.com/V-Sekai/godot-modules-groups.git $SCRIPTPATH/../../modules
git clone https://github.com/V-Sekai/casync-v-sekai-game.git $SCRIPTPATH/../../casync
git clone https://github.com/V-Sekai/godot-vsekai-merge.git $SCRIPTPATH/../../merge
cp -rf $SCRIPTPATH/vscode $SCRIPTPATH/../../.vscode
