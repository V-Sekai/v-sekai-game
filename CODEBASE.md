<h1 align="center">V-Sekai GDScript</h1>

Map of `addon/` components.
- :gear: Engine C++ Interface
- :warning: Unused (See also [Warnings](#warnings))

```mermaid
%%{init: {'themeVariables': { 'fontSize': '22px' }}}%%
flowchart TD
        Audio --> addon1[**kenney_ui_audio**<hr>UI sound sfx .wav library]
        Audio --> addon2[**godot_speech** ⚙️<hr>Audio packets decoder/encoder]
        Network --> addon3[**network_manager**<hr>Manages network settings, logic, physics, spawning commands...]
        Network --> addon4[**godot_uro**<hr>Uro API server interface to send requests for login, avatars, maps upload/download]

    classDef Category font-size:30px
    class Audio,Network Category
```

```mermaid
%%{init: {'themeVariables': { 'fontSize': '22px' }}}%%
flowchart TD
        UI --> Menu
        Menu --> addon5[**vsk_menu**<hr>Main title menus and in-game menus]
        Menu --> addon6[**navigation_controller**<hr>Menu state controller for menu switching]
        UI --> addon7[**fade_manager**<hr>Controls full screen fading including in VR]
        UI --> addon8[**canvas_plane**<hr>Utility to position Godot control nodes in 3D space]
        UI --> addon9[**textureRectUrl**<hr>Image preview controls for UI item grids]
        UI --> addon10[**emote_theme**<hr>Font files and theme settings]

    classDef Category font-size:30px
    class UI Category
```

```mermaid
%%{init: {'themeVariables': { 'fontSize': '22px' }}}%%
flowchart TD
        Game --> addon11[**vsk_manager**<hr>Main game logic]
            addon11 --> ctrl1{" "}
            ctrl1 --> dir1{**vsk_startup_manager.gd**<hr>Game Entrypoint}
            ctrl1 --> dir2[**outside_game_root_vr.tscn**<hr>Debug Menu scene]
            ctrl1 --> dir3[**vsk_asset_manager.gd**<hr>Manages http or local requests of assets]
            ctrl1 --> dir4[**xr_vignette/**<hr>test]
        Game --> addon12[**background_loader**⚙️<hr>Interface for resource load requests with whitelist]

    classDef Category font-size:30px
    class Game Category

```

```mermaid
%%{init: {'themeVariables': { 'fontSize': '22px' }}}%%
flowchart TD
        Entities --> addon13[**vsk_avatar**<hr>Avatar definition, load/setup of bones, IK, hand poses]
        Entities --> addon14[**vsk_map**<hr>Class definitions for game Maps]
        Entities --> addon15[**entity_manager**<hr>Manages in-game entities and logic, physics, scene spawing and network coordination]
        Entities --> addon16[**vsk_entities**<hr>Game entities initialization. Contains player avatar main scene.]
            addon16 --> ctrl1{" "}
            ctrl1 --> dir1[**vsk_player_old.tscn**<hr>Current player Avatar entity instance]
        addon17 --> dir2

    classDef Category font-size:30px
    class Entities Category

```

```mermaid
%%{init: {'themeVariables': { 'fontSize': '22px' }}}%%
flowchart TD
        Actor --> addon18[**state_machine**<hr>Base class for state machines]
        Actor --> addon19[**godot_state_charts**<hr>Base class for Actor animation states]
        Actor --> addon20[**actor**<hr>Player actor state machine and camera controller]
            addon20 --> dir1["**states**<hr>Actor states(jump, fall...) for state machine"]
        Editor --> addon21[**vsk_importer_exporter**<hr>Avatar/scene import and export validation]
        Editor --> addon22[**vsk_editor**<hr>Editor plugin for uploading Maps/Avatars to Uro server]

    classDef Category font-size:30px
    class Actor Category

```

```mermaid
%%{init: {'themeVariables': { 'fontSize': '22px' }}}%%
flowchart TD
        VR-XR --> Input
        Input --> addon23[**input_manager**<hr>Input device setup for Joypad/Mouse]
        Input --> addon24[**sar1_vr_manager**<hr>Main VR Controller. Manages HMD settings, trackers, render tree.]
            addon24 --> dir1[**components**<hr>Lasso, Teleport, Hand Pose, Locomotion functions]
        VR-XR --> Render
            Render --> ctrl1{" "}
            ctrl1 --> ctrl2{" "}
            ctrl2 --> addon25[**spatial_game_viewport_manager**<hr>Manages viewport size changes]
            ctrl2 --> addon26["**flat_viewport**<hr>Control for handling offscreen rendering (from a VR device for example)"]
            ctrl2 --> addon27[**xr_vignette**<hr>Experimental camera tunnel shader to reduce motion sickness]
        VR-XR --> Utils
            Utils --> addon29[**sar1_screenshot_manager**<hr>Utility to capture screenshots]

    classDef Category font-size:30px
    class VR-XR Category

```

```mermaid
%%{init: {'themeVariables': { 'fontSize': '22px' }}}%%
flowchart TD
        VRM --> addon30[**vrm**<hr>Godot VRM Avatar implementation]
        VRM --> addon31[**Godot-MToon-Shader**<hr>Godot Toon shader for VRM Avatars]
        VRM --> addon32[**vsk_vrm_avatar_tool**<hr>VRM Avatar Converter]

    classDef Category font-size:30px
    class VRM Category
```

```mermaid
%%{init: {'themeVariables': { 'fontSize': '22px' }}}%%
flowchart TD
        Misc --> Utils
            Utils --> addon33[**vsk_version**<hr>Version Strings]
            Utils --> addon34[**gd_util**<hr>Generic utility functions for 3d transforms, camera]
            Utils --> addon35[**math_util**<hr>Utility math functions]
        Misc --> 3D
            3D --> ctrl1{" "}
            ctrl1 --> addon38[**extended_kinematic_body**<hr>Improved CharacterBody3d with better tolerance for stairs/slopes]
        Misc --> addon39[**smoothing**<hr>Fixed timestep interpolation addon for framerate independent physics]

    classDef Category font-size:30px
    class Misc Category
```

## Warnings

### vsk_entities/vsk_player.tscn
Unused code is also in addons/vsk_entities/extensions.

### smoothing
Deprecated by native lerp, needs replacing. See https://github.com/godotengine/godot-docs/pull/10197
