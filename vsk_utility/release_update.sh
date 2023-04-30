#!/usr/bin/env bash

cd ../../vsk_godot
git fetch
git checkout groups-4.x -f
git reset --hard origin/groups-4.x
cd -