# Unidot Importer

Unidot Importer is a Unity compatibility layer and `.unitypackage` importer for Godot 4.x.

## Engine patches

Please use the latest Godot 4.0 alpha builds ( `master` branch of https://github.com/godotengine/godot ) to run this addon.

## Features

- Translates Unity filetypes (such as .unity or .mat) to Godot native scene or resource types.
- Supports both binary and text YAML encoding
- Implementation of an asset database for unity assets by GUID
- `.unitypackage` importer and translation shim.
- preliminary animation and animation tree porting.
- We rely on automatic FBX to glTF translation during `.unitypackage` import using FBX2glTF. please download the FBX2glTF exe

Note that scripts and shaders will need to be ported by hand. However, it will be possible to map from the unity scripts/shaders to Godot equivalents after porting.

Many import settings in Unity are not implemented in Godot Engine, such as recomputing tangents or specific texture compression settings.

Canvas / UI is not implemented.

## Unsupported

- Shader porting: a system will be added to create mappings of equivalent Godot Engine shaders, but porting must be done by hand.
- C# Script porting

## Installation notes:

1. This project should be imported at `addons/unidot` in the project, often as a git submodule.

2. Most unity assets use .fbx files. To support FBX requires additional setup:

  Godot's .fbx implementation is incomplete and can corrupt normals or fail in typical cases, such as FBX files exported by Blender.

  To install, one must download FBX2glTF from https://github.com/revolufire/FBX2glTF/releases/, then rename to FBX2glTF.exe and move it into this addon directory.

3. To add TIFF / .tif support, install ImageMagick and copy convert.exe into this addon directory.

4. Finally, enable the Unidot Importer plugin in `Project Settings -> Plugins tab -> Unidot`

5. Access the importer through `Project -> Tools -> Import Unity Package...`

## A final note:

This tool is designed to assist with importing or translating source assets made for Unity Engine. It assumes text serialization (such as within a `.unitypackage` archive) and typical asset conventions (for example, an assumption that most files contain only one asset).

Unidot solely translates existing usable source assets into equivalent Godot source assets. There are no plans to add functionality for decompiling asset bundles or ripping unity content. That is not the goal of this project.
