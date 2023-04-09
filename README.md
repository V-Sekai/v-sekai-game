# V-Sekai

## How do I get involved?

We're happy to accept pull requests for features and bug fixes. Please join our [official Discord server](https://discord.gg/7BQDHesck8) for more information.

- Website: [https://v-sekai.org/](https://v-sekai.org/)
- Twitter: [https://twitter.com/vsekaiofficial](https://twitter.com/vsekaiofficial)
- Discord: [https://discord.gg/7BQDHesck8](https://discord.gg/7BQDHesck8)

You can find our issues and suggestions at the [documentation website](https://v-sekai.github.io/manuals).

V-Sekai is still in a pre-release state. It's highly experimental and still being evaluated for security. Use at your own risk.

## What is it?

V-Sekai is an open-source project that aims to bring social VR/VRSNS/metaverse components to the [Godot Engine](https://godotengine.org), including:

- A generic multiplayer framework with VOIP support
- Tools for loading and generating arbitrary user-generated content from the Godot Engine.
- Avatar support with inverse kinematics.

## How do I get it?

V-Sekai is still in a pre-release state. We don't offer pre-packaged downloads yet. It's highly experimental and still being evaluated for security. Use at your own risk.

We also provide [preview builds](https://v-sekai.github.io/manuals/features/play_latest.html).

## How do I build it?

V-Sekai requires our [custom Godot Engine fork](https://github.com/v-sekai/godot) found under the `groups-4.x` branch, as well as our [custom engine modules](https://github.com/V-Sekai/godot-modules-groups) under the `main`. For information about building the Godot Engine, see the [official documentation](https://docs.godotengine.org/en/latest/contributing/development/compiling/). You must also add the `custom_modules` path when invoking scons. More information about custom modules can be found [here](https://docs.godotengine.org/en/latest/contributing/development/core_and_modules/custom_modules_in_cpp.html)
