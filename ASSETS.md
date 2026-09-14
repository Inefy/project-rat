# Third-party assets

## Kenney visual assets

| Source pack | Files used in this repository | License |
| --- | --- | --- |
| [Animal Pack Remastered](https://kenney.nl/assets/animal-pack-remastered) | `assets/kenney/animals/parrot.png`, `owl.png`, `snake.png`, `dog.png` | [CC0 1.0](third_party/licenses/kenney-animal-pack-remastered.txt) |
| [Background Elements Remastered](https://kenney.nl/assets/background-elements-remastered) | `assets/kenney/background/tree.png`, `treeSmall_green2.png`, `treeSmall_green3.png`, `bush1.png`, `bushAlt1.png`, `fence.png` | [CC0 1.0](third_party/licenses/kenney-background-elements-remastered.txt) |
| [UI Pack - Adventure](https://kenney.nl/assets/ui-pack-adventure) | `assets/kenney/ui/button_brown.png`, `button_red.png` | [CC0 1.0](third_party/licenses/kenney-ui-pack-adventure.txt) |

The remaining Kenney scenery and UI visuals are used as downloaded. Menu portraits and gameplay entities now use original Blender renders.

The original 24-model picnic cast is authored with Blender Python and rendered into 94 transparent PNGs under `assets/sprites`. The concept sheet was generated with the built-in image-generation tool, drawing on late-N64 cartoon styling; it contains original cast designs rather than extracted commercial game assets. See `art/README.md` for the asset inventory and production workflow. The backyard, particles, and UI also use GDScript drawing. The sound effects below are redistributed under Creative Commons Zero 1.0 (CC0).

The regular cat was subsequently remodeled in Blender from the user-supplied drawing preserved as `art/references/cat-design.png`. Its geometry and vertex colors are authored in `tools/cat_model.py`; no third-party mesh or texture library is used.

## Kenney audio

| Source pack | Files used in this repository | License |
| --- | --- | --- |
| [Impact Sounds](https://kenney.nl/assets/impact-sounds) | `enemy_hit.ogg`, `player_hit.ogg`, `wave_clear.ogg` | [CC0 1.0](third_party/licenses/kenney-impact-sounds.txt) |
| [Sci-Fi Sounds](https://kenney.nl/assets/sci-fi-sounds) | `shoot.ogg`, `power_shoot.ogg`, `enemy_death.ogg`, `shield.ogg`, `venom.ogg` | [CC0 1.0](third_party/licenses/kenney-sci-fi-sounds.txt) |
| [UI Audio](https://kenney.nl/assets/ui-audio) | `ui_click.ogg`, `ui_hover.ogg`, `pickup.ogg`, `dash.ogg` | [CC0 1.0](third_party/licenses/kenney-ui-audio.txt) |

The files are stored in `assets/audio/` under descriptive names. Credit is not required by CC0, but Kenney's generous asset library deserves the shout-out.

## Original atmosphere and feedback

`assets/audio/night_drone.wav` is an original, mathematically synthesized 12-second ambient loop, built from low sine tones with slow amplitude modulation. It contains no third-party samples and is covered by the repository license. The eclipse, watchers, drifting fog, pickup bursts, and damage overlay are drawn directly in GDScript.

The top-down game uses the Blender-rendered sprites in `assets/sprites/`. Original GLB models remain in `art/models/` and `assets/models/` for reuse; they are excluded from the web package.
