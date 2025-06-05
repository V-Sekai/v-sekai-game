<a id="readme-top"></a>

<div align="center">
  <a href="https://github.com/V-Sekai/v-sekai-game">
    <img src="vsk_default/icon/v_sekai_logo_bg.svg" alt="Logo" width="300" height="300">
  </a>

  <h1 align="center">V-Sekai</h1>

  <p align="center">
    <i>“Open-source Social VR for everyone”</i>
    <br />
    <br />
    <a href="https://github.com/V-Sekai/v-sekai-game/"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/V-Sekai/v-sekai-game/issues/new?assignees=&labels=enhancement&projects=&template=feature_proposal.yml">Request Feature</a>
    ·
    <a href="https://github.com/V-Sekai/v-sekai-game/issues/new?assignees=&labels=bug&projects=&template=bug_report.yml">Report Bug</a>
  </p>
</div>

<br />

:construction: <i><ins>**Caution:**</ins> In active development, new builds may break. Current **nightly editor builds** are available at [nightly.link - Github](https://nightly.link/V-Sekai/world-godot/workflows/build.yaml/main?preview).</i>

## What is it? :video_game: :milky_way:

**V-Sekai** is an **open-source** project that aims to bring social **VR/VRSNS/metaverse** components to the [Godot Engine](https://godotengine.org), including:

- A generic **multiplayer** framework with **VoIP** support
- Tools for loading and generating arbitrary **user-generated content** from the Godot Engine.
- **Avatar** support with inverse kinematics.

The project is split in **three** main components:
- **Game client:** [V-Sekai/v-sekai-game](https://github.com/V-Sekai/v-sekai-game)
- **Map editor:** [V-Sekai/world-godot](https://github.com/V-Sekai/world-godot)
- **Server backend:** [V-Sekai/uro](https://github.com/V-Sekai/uro)

Regular users will only need the **game client** to access VR spaces.

## How do I get it? :mag:

V-Sekai is still in a **pre-release** state. We offer only **experimental** builds for regular users in [Releases Section](https://github.com/V-Sekai/v-sekai-game/releases).

If you are a __*developer*__ or want to __*experiment*__ we provide builds for our **custom Godot editor** via **Github Actions** at [nightly.link - Github](https://nightly.link/V-Sekai/world-godot/workflows/build.yaml/main?preview). Older stable builds **"groups-4.2"** are available at our former main [editor repository](https://github.com/V-Sekai/godot/releases/tag/groups-4.2.2023-09-20T191915Z).

You can **clone** this repository and **import** in the editor to get started. See [How to contribute](#how-do-i-help-contribute-books) for more instructions.

Some files are provided in parts as **split zip** archives (.zip.001 .zip.002...). To **extract them** download all same name parts, move them to a folder and extract the .zip.001 file with software like [**7-zip**](https://www.7-zip.org/) or [**PeaZip**](https://peazip.github.io/) (macOS).

This project is highly experimental and still being evaluated for security. Hosting public instances is not recommended. :warning:<ins>**Use at your own risk!**</ins>:warning:

## How do I get involved? :busts_in_silhouette:

We're happy to accept pull requests for **features** and **bug fixes**. 

- **Website:** :link:[https://v-sekai.org/](https://v-sekai.org/)
- **X (Twitter):** :link:[https://x.com/vsekaiofficial](https://x.com/vsekaiofficial)
- **Discord:** <a href="https://discord.gg/H3s3PD49XC">
        <img src="https://img.shields.io/discord/1138836561102897172?logo=discord"
            alt="Chat on Discord"></a>

You can find our issues and suggestions at the [documentation website](https://v-sekai.github.io/manuals).

## How do I help contribute? :books:
We are looking for developers and content creators for avatar and maps.

### Avatars and Maps
1. Download latest editor
2. Register on [V-Sekai](https://v-sekai.org/) (Required for upload)
3. Ask on [**Discord**](https://discord.gg/H3s3PD49XC) for manual account approval and further instructions.

### Game development
V-Sekai requires our [custom Godot Engine fork](https://github.com/V-Sekai/world-godot). For information about building the Godot Engine, see the [official documentation](https://docs.godotengine.org/en/latest/contributing/development/compiling/).

An overview of GDScript game code is available in [CODEBASE.md](CODEBASE.md).

## License :page_facing_up:

Distributed under the MIT License. See `LICENSE` file for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>
