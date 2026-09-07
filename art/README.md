# Picnic public enemies

Original chunky cartoon assets for Project R.A.T. The concept sheet references the exaggerated late-N64 comedy aesthetic requested by the user. Models are simplified interpretations of that sheet.

- `concept-prompt.txt`: exact prompt used with built-in imagegen.
- `cast-concept.png`: built-in imagegen production mockup, ten characters and fourteen props.
- `picnic-cast.blend`: editable Blender 5.2 model library. Opens to **Picnic Cast Gallery**; **RAT Asset Studio** holds origin-centered render models. The pre-existing default scene is preserved.
- `models/*.glb`: 24 portable models with materials and named parts.
- `sprite-catalog.png`: actual in-engine render catalog, distinct from the concept art.
- `asset-manifest.json`: inventory and approximate polygon-derived triangle budgets.
- `../assets/sprites/*.png`: 94 RGBA images, 192 x 192. Ten characters x eight facings, fourteen props x one view.

Characters: rat, bird, cat, owl, snake, raccoon, fox, alpha_cat, junkyard_dog, barn_owl.

Pickups: cheese, rapid (chili), triple (peas), power (acorn), haste (sugar), shield (lid), pierce (tooth).

Projectiles and props: seed, feather, venom, bone, sonic, crumb, fizzy.

The 2D game consumes rendered sprites, not live 3D scenes. Direction 0 faces right; directions advance clockwise in 45-degree steps. Sprite drawing counters the entity rotation, keeping the camera perspective upright. Movement has procedural bounce/squash; the models do not contain skeletal rigs or baked walk/attack clips. Elite badges, armour plates/bars, attack warnings, dash trails and shield effects remain live gameplay overlays.

Art and tools have `.gdignore` files so the browser package does not import Blender sources or the large concept sheet. All sprite paths use explicit preloads for reliable exports. Existing scenery is retained.

## Reproduce

Use Blender 5.2 and Godot 4.7.2. Start the model build in a fresh Blender document:

```
blender --background --python tools/build_picnic_assets.py
blender --background art/picnic-cast.blend --python tools/build_picnic_assets.py -- --render
blender --background art/picnic-cast.blend --python tools/prepare_picnic_gallery.py
godot --headless --path . --import
godot --headless --path . --script tests/model_art_test.gd
godot --path . --script tests/model_art_test.gd
godot --headless --path . --export-release Web build/web/index.html
python tools/serve_preview.py
```

The graphical art test creates the catalog. The preview server supplies the isolation headers required by the threaded browser export at http://127.0.0.1:8765. The scripts resolve the checkout from their own locations. Pass a different port to the preview server when an existing PWA cache is stale: `python tools/serve_preview.py 8766`.

Validation: gameplay smoke suite, fun systems suite, all 94 textures present/nonempty, graphical catalog and gameplay screenshots, local web export and browser interaction.
