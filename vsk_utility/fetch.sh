#!/usr/bin/env bash

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

git clone https://github.com/V-Sekai/godot.git $SCRIPTPATH/../../vsk_godot -b groups-4.x
git clone https://github.com/V-Sekai/casync-v-sekai-game.git $SCRIPTPATH/../../vsk_casync
git clone https://github.com/V-Sekai/godot-vsekai-merge.git $SCRIPTPATH/../../vsk_merge
cp -rf $SCRIPTPATH/vscode $SCRIPTPATH/../../.vscode
