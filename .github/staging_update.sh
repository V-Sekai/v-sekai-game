#!/usr/bin/env bash

cd ../../vsk_godot
git fetch
git checkout groups-staging-4.x -f
git reset --hard origin/groups-staging-4.x
cd -