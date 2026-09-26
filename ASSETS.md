# Third-party assets

## Kenney visual assets

| Source pack | Files used in this repository | License |
| --- | --- | --- |
| [Animal Pack Remastered](https://kenney.nl/assets/animal-pack-remastered) | `assets/kenney/animals/parrot.png`, `owl.png`, `snake.png`, `dog.png` | [CC0 1.0](third_party/licenses/kenney-animal-pack-remastered.txt) |
| [Background Elements Remastered](https://kenney.nl/assets/background-elements-remastered) | `assets/kenney/background/tree.png`, `treeSmall_green2.png`, `treeSmall_green3.png`, `bush1.png`, `bushAlt1.png`, `fence.png` | [CC0 1.0](third_party/licenses/kenney-background-elements-remastered.txt) |
| [UI Pack - Adventure](https://kenney.nl/assets/ui-pack-adventure) | `assets/kenney/ui/button_brown.png`, `button_red.png` | [CC0 1.0](third_party/licenses/kenney-ui-pack-adventure.txt) |

The remaining Kenney scenery and UI visuals are used as downloaded. Gameplay entities use original Blender renders; menus use plain backgrounds.

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

## Interface type

The interface uses Barlow Condensed SemiBold by Jeremy Tribby for headings and DM Sans for controls and body text. Both have their SIL Open Font License 1.1 files in `assets/fonts/`. Newsreader remains available as a source font from the previous interface. Barlow source: https://github.com/google/fonts/tree/main/ofl/barlowcondensed.

`assets/ui/rat-portrait.png` is the project's original Blender-rendered rat portrait, copied from `art/nightmare-cast/rat-preview.png` for the title screen. Menu scenery is drawn in `scripts/menu_backdrop.gd`.

### Nightmare UI redesign

- `assets/ui/nightmare-garden.png`: former menu background, preserved as source art and excluded from the web export. Menus now use solid charcoal backgrounds. Its ImageGen mockups and prompts are preserved in `art/ui-redesign/nightmare-design.md`.
- Newsreader: Production Type, SIL Open Font License 1.1; `assets/fonts/OFL-Newsreader.txt`. Source: https://github.com/google/fonts/tree/main/ofl/newsreader.
- DM Sans: Colophon Foundry, SIL Open Font License 1.1; `assets/fonts/OFL-DMSans.txt`. Source: https://github.com/google/fonts/tree/main/ofl/dmsans.
- Upgrade symbols are original Blender renders in `assets/upgrades/`, displayed by `scripts/upgrade_icon.gd`. Toggles and slider knobs are project-authored SVG controls.

### Remaining nightmare cast

`art/nightmare-cast/mockups.png` was generated with the built-in imagegen tool; the complete prompt is preserved in `art/nightmare-cast/mockup-prompt.txt`. The five replacement characters, seven pickup models, and sixteen mutation icons are original Blender geometry authored in `tools/nightmare_models.py`. Their source is `art/nightmare-cast/nightmare-cast.blend`, and the full cast library is synchronized in `art/picnic-cast.blend`. Materials use vertex colors and procedural shading; no third-party meshes or texture downloads were used.
