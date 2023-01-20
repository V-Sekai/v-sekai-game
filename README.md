# V-Sekai

## What is it?

V-Sekai is an open source project aiming to bring social VR/VRSNS/metaverse components to the [Godot Engine](https://godotengine.org) which includes:

- A generic multiplayer framework with VOIP support.
- Full VR integration with object interaction.
- Tools for loading and generating abitrary user-generated content from the Godot Engine.
- Sandboxed WASM scripting environment.
- Full-body avatar support with inverse kinematics.

## How do I get it?

V-Sekai is still currently in a pre-release state. We do not currently offer pre-packaged downloads as of yet.
It is also highly experimental and due to its focus on providing native user-generated content support, is still being
evaluated for security. Use at your own risk.

[nightly.link provided downloads for the editor.](https://nightly.link/V-Sekai/v-sekai-game/workflows/build-project/main)

## How do I build it?

V-Sekai requires our [custom Godot Engine fork](https://github.com/v-sekai/godot) found under the `groups-4.x` branch, as well 
our [custom engine modules](https://github.com/V-Sekai/godot-modules-groups) under the `main`. For information about building the Godot Engine, see the
[official documentation](https://docs.godotengine.org/en/latest/contributing/development/compiling/). You must also add the `custom_modules` path when
invoking scons. More information about custom modules can be found [here](https://docs.godotengine.org/en/latest/contributing/development/core_and_modules/custom_modules_in_cpp.html)

## How do I get involved?

We're happy to accept pull requests for features and bug fixes. Please join our [official Discord server](https://discord.gg/7BQDHesck8) for more information.

Website: <https://v-sekai.org/><br>
Twitter: <https://twitter.com/vsekaiofficial><br>
Discord: <https://discord.gg/7BQDHesck8><br>

You can find our issues and suggestions at the [V-Sekai.github.io repository.](https://github.com/V-Sekai/V-Sekai.github.io).

See our [documentation website](https://v-sekai.github.io/).
