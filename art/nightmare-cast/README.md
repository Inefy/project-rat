# Remaining nightmare cast and upgrade art

The five previously unchanged characters now follow the existing surreal creature style: flat vertex-colored paint, irregular black contours, shaded human eyes and hands, and separate silhouettes.

## Deliverables

- `mockups.png`: initial five-character concept sheet, generated with the built-in imagegen tool. `mockup-prompt.txt` records its exact prompt.
- `nightmare-cast.blend`: editable source with named parts for five characters, seven pickups, and sixteen mutation icons. The concept image is packed into the file. Opens with the rat visible; the other models are organized in named collections.
- `*-preview.png`: actual Blender renders, separate from the generated concept sheet.
- `production-sheet.png`: Godot capture of the shipped sprites and all sixteen card icons.
- `stats.json`: measured geometry and file sizes for the twelve reusable models.
- `../picnic-cast.blend`: the complete cast gallery, synchronized with these replacements.
- `../models/*.glb` and `../../assets/models/*.glb`: matching portable exports. These contain vertex colors; no external image textures are required.
- `../../assets/sprites/`: forty directional creature sprites and seven pickup sprites, all transparent 192 × 192 PNGs.
- `../../assets/upgrades/`: sixteen transparent 192 × 192 mutation textures, explicitly preloaded by `scripts/upgrade_icon.gd`.

## Designs

| Character | Distinguishing features |
| --- | --- |
| Rat | Pink ears and curling tail, uneven human eyes, incisors, blue vest, red scarf, fingers around a green seed blaster |
| Raccoon | Gray hunched body, black mask, tired eyes, striped upright tail, human hands, eyeball mounted in a bin lid |
| Alpha Cat | Tall black body, green ring eyes, crooked crown, ragged burgundy cape, oversized human hands, blade tail |
| Junkyard Dog | Low ochre body, square head, mismatched eyes, human lips and teeth, spiked collar, human forehands |
| Barn Owl | Ivory heart face, mismatched eyes, dark feather fans, teal markings, dangling hands, forked feet |

`NIGHTMARE_Paint` exports as `KHR_materials_unlit`. Skin, eyes, and metal remain shaded. Blender renders their detail into sprites for the browser. These are static models with the game's existing procedural movement; they are not rigged animations. Front is -Y, ground is Z=0.

The upgrade textures use distinct silhouettes: bounce paths, split shots, three/five seed orbits, a fuse-eyed bomb, a recharge arrow, a stitched heart, a fang, a seed held in a hand, a lucky tail, and a cheese magnet. Related temporary pickups and permanent mutations share their visual vocabulary. Dark pickup medallions keep pale sugar and teeth readable.

## Rebuild

From the repository root, with Blender 5.2 and Godot 4.7.2:

```sh
blender --background --factory-startup --python-exit-code 1 --python tools/build_nightmare_cast.py
blender --background art/picnic-cast.blend --python-exit-code 1 --python tools/sync_nightmare_cast.py
godot --headless --path . --import
godot --headless --path . --script tests/nightmare_art_test.gd
godot --headless --path . --script tests/model_art_test.gd
godot --headless --path . --script tests/cast_integration_test.gd
```

For a quick render iteration use `-- --only rat,raccoon` or `-- --icons`. A partial run updates exports and PNGs; only a complete run updates `nightmare-cast.blend`. Run the complete build before synchronizing the cast library.

Graphical runs of `tests/nightmare_art_test.gd` and `tests/cast_integration_test.gd` refresh the production sheet and `art/all-models-in-game.png`. `tests/capture_fun_preview.gd` captures the actual mutation draft in `build/fun-draft.png`.

## Validation

- All twelve character/pickup GLBs import with authored vertex colors. The creature meshes keep separate unlit paint / shaded anatomical materials. `tools/import_nightmare_model.gd` explicitly enables vertex colors on Godot's unlit imports.
- All forty character facings, seven pickup textures, and sixteen unique mutation textures have visible pixels and transparent margins.
- The complete cast test spawns all ten characters and fourteen props through production game paths.
- Gameplay smoke, upgrade systems, and normal/large-text interface checks pass.
- The local web export was played through wave one into the mutation draft, where the new textures displayed correctly with no browser warnings or errors. GLBs and Blender source are excluded from the web download.

Collisions, wave introductions, attacks, and upgrade effects retain their existing behavior. Raccoon, Alpha Cat, and Barn Owl sprites have more room for their silhouettes; health bars clear the top of every creature.
