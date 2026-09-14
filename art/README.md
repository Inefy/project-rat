# Picnic public enemies

Original chunky cartoon assets for Project R.A.T. The concept sheet references the exaggerated late-N64 comedy aesthetic requested by the user. The current cast expands those concepts with separate body plans, facial proportions, costumes, and silhouettes for all ten characters.

- `concept-prompt.txt`: exact prompt used with built-in imagegen.
- `cast-concept.png`: built-in imagegen production mockup, ten characters and fourteen props.
- `picnic-cast.blend`: editable Blender 5.2 model library. Opens to **Picnic Cast Gallery**; **RAT Asset Studio** holds origin-centered render models. The pre-existing default scene is preserved.
- `models/*.glb`: 24 portable models with materials and named parts.
- `sprite-catalog.png`: actual in-engine render catalog, distinct from the concept art.
- `cast-lineup.png`: current cast in front and three-quarter views, with 64px silhouettes and rear views to check recognition at gameplay size.
- `asset-manifest.json`: inventory and approximate polygon-derived triangle budgets.
- `../assets/sprites/*.png`: 94 RGBA images, 192 x 192. Ten characters x eight facings, fourteen props x one view.

Characters: rat, bird, cat, owl, snake, raccoon, fox, alpha_cat, junkyard_dog, barn_owl.

## Character identities

| Character | Shape and identifying features |
| --- | --- |
| Rat | Huge pink ears, lean blue waistcoat, red scarf, buck teeth and seed blaster. |
| Bird | Compact blue egg, wide wings, swept yellow quiff and a large wedge beak. |
| Cat | Reference-matched black quadruped, tall ears, charcoal face and chest, green ring eyes, bloodied fangs, human hands and a curved blade tail. |
| Owl | Four outlined ochre feather fans, blank white eyes, slate-blue beak, stick legs, and a shaded human belly button on a flat MS Paint body. |
| Snake | Broad coil, S-shaped neck, lime belly, hood, flat muzzle and forked tongue. |
| Raccoon | Hunched slate shoulders, black mask, round ears, striped tail and enormous bin lid. |
| Fox | MS Paint orange silhouette and uneven white brush strokes, with shaded human ears and tired eyes; black-dot nose and flat magenta tongue. |
| Alpha Cat | Magenta monarch, wide burgundy cape, ermine trim and tall crooked crown. |
| Junkyard Dog | Square torso, massive forepaws, drooping jowls, underbite and spiked red collar. |
| Barn Owl | Ivory heart-shaped face, swept dark wings, teal academic gown and mortarboard. |

`tools/character_designs.py` is the editable cast recipe; `tools/build_picnic_assets.py` supplies geometry, materials, and rendering. The replacement cat's detailed geometry is in `tools/cat_model.py`, with its dedicated build and lighting in `tools/build_reference_cat.py`. Character framing is fitted across all eight directions so tails, wings, ears, and crowns retain transparent margins. The art regression test checks these margins.

## Reference cat

The supplied drawing is preserved in `references/cat-design.png` and packed into `cat/reference-cat.blend`. The standalone Blender studio retains named, editable parts and a presentation camera. The same cat is installed in `picnic-cast.blend` and replaces `models/cat.glb` and the eight production `cat_*.png` sprites. Alpha Cat retains its separate boss design.

The GLB contains **16,381 triangles**, **one mesh**, **three materials**, and **no texture images**; its uncompressed download is **416,440 bytes**. Fine surface detail uses vertex colors and simplified geometry. See `cat/cat-stats.json` for measured output. The top-down browser game uses eight 192 x 192 directional sprites, totaling 225,979 bytes. GLB files are excluded from the web package. An identical GLB in `assets/models/cat.glb` remains available for reuse.

`tools/import_cat_model.gd` preserves vertex-color materials during Godot import for GLB reuse. The iris has constant green emission for correct glTF export, and Godot generates LODs at import. `tests/cat_model_test.gd` validates the model budget, materials and production sprite sizes; `tests/top_down_test.gd` checks the camera, movement, aiming, projectile collision and pause flow. `tests/capture_cat_gameplay.gd` captures the cat in the top-down arena.

The model preserves the reference's major features; hand skin detail is simplified for the mesh budget, and the rear anatomy is inferred from the single supplied view. It is a static model without an armature or animation clips; the existing game supplies procedural bounce and squash.

To rebuild just this cat, without regenerating the other characters:

```
blender --background --factory-startup --python-exit-code 1 --python tools/build_reference_cat.py
blender --background art/cat/reference-cat.blend --python-exit-code 1 --python tools/build_reference_cat.py -- --render
blender --background art/picnic-cast.blend --python-exit-code 1 --python tools/sync_reference_cat.py
godot --headless --path . --import
godot --headless --path . --script tests/model_art_test.gd
godot --headless --path . --script tests/cat_model_test.gd
```

Pickups: cheese, rapid (chili), triple (peas), power (acorn), haste (sugar), shield (lid), pierce (tooth).

## Reference fox

The supplied image is preserved in `references/fox-design.png` and packed into `fox/reference-fox.blend`. Named editable parts include the uneven orange silhouette, long snout, white brush strokes, pink tongue dab, curled tail, and human ear shells, helixes, antihelixes, tragi and lobules. Half-closed eyes have colored irises, heavy lids and red under-eye bags. The back and depth are inferred from the single reference view. The model is static; the game supplies its procedural bounce, squash and ambush movement.

`tools/fox_model.py` defines the geometry. `tools/build_reference_fox.py` builds the standalone studio, exports a single mesh, and renders eight 192px RGBA production directions. `tools/sync_reference_fox.py` installs the editable fox into the existing cast studio and gallery. The shared cast recipe also uses this geometry.

Measured export: **12,698 triangles**, **6,487 Blender vertices**, **three materials**, **zero textures**, **313,748 GLB bytes**. Both `models/fox.glb` and `../assets/models/fox.glb` contain the same export. `tools/import_fox_model.gd` preserves vertex colors, and Godot generates distance LODs. The top-down game loads only the eight sprite images, totaling **43,777 bytes**; GLBs and Blender sources remain excluded from the browser package. The `FOX_Paint` material exports as `KHR_materials_unlit`; skin and eyes remain lit. Standard color management, disabled dithering, and lossless PNG compression preserve exact flat fill and reduce the eight sprites by 76% from the initial shaded version. Procedural skin pores are baked into these sprites without shipping textures. Fox sprites retain their authored colors, use additional space for ears and tail, and place health bars above the ears. Collision size and combat timings are preserved.

Rebuild only the reference fox:

```sh
blender --background --factory-startup --python-exit-code 1 --python tools/build_reference_fox.py -- --all
blender --background art/picnic-cast.blend --python-exit-code 1 --python tools/sync_reference_fox.py
godot --headless --path . --import
godot --headless --path . --script tests/fox_model_test.gd
godot --headless --path . --script tests/model_art_test.gd
godot --path . --script tests/capture_fox_gameplay.gd
```

`fox/fox-preview.png` shows the Blender studio render; `fox/directions.png` shows the eight shipped facings; `fox/in-game.png` captures the production sprites in the arena. `tests/fox_model_test.gd` checks the imported geometry, unlit paint versus lit skin/eyes, exact orange sprite fill, LODs, a 320 KiB model budget, a 64 KiB total sprite budget, directional completeness, wave-ten spawning, and warning/dash/recovery sequence. CI runs it before publishing.

Projectiles and props: seed, feather, venom, bone, sonic, crumb, fizzy.

## Reference four-wing owl

`references/owl-design.png` preserves the supplied drawing and is packed into `owl/reference-owl.blend`. `tools/owl_model.py` authors its four feather fans, rounded feather tips, ink quills/barbs, uneven ochre silhouette, two blank white eyes, slate-blue beak, black mouth dot, and forked stick-leg motif. The human navel uses a shaded cavity with puckered folds, vertex colors, and procedural pores baked into the sprites. Front is -Y and ground is Z=0; depth and back anatomy are inferred from the single view. Upper wings sweep back and lower wings forward so the owl remains recognizable in side views.

The GLB has **17,708 triangles**, **10,574 source vertices**, **one mesh**, **two materials**, **zero textures**, and **489,152 bytes**. `OWL_Paint` exports as `KHR_materials_unlit`; `OWL_Skin` keeps per-pixel shading. Both `models/owl.glb` and `../assets/models/owl.glb` contain the same export. Godot generates LODs, and `tools/import_owl_model.gd` preserves the painted and skin vertex colors.

The actual browser game uses eight **192 x 192 RGBA** sprites totaling **95,780 bytes**. Flat fill, disabled dithering, lossless PNG compression, and removal of Blender's render metadata keep the download small; pixel data and PNG color information are retained. Sources, reference images and GLBs are excluded from the web package. The renderer preserves the owl's authored colors, gives its four wings more space, and draws health bars above the wings. Its 23-unit collision radius, wave-three introduction, attack warning and three-feather volley are preserved. The Barn Owl boss retains its own model. The owl is static, with the game's existing procedural bounce and movement.

Rebuild and validate only this owl:

```sh
blender --background --factory-startup --python-exit-code 1 --python tools/build_reference_owl.py -- --all
blender --background art/picnic-cast.blend --python-exit-code 1 --python tools/sync_reference_owl.py
godot --headless --path . --import
godot --headless --path . --script tests/owl_model_test.gd
godot --headless --path . --script tests/model_art_test.gd
godot --path . --script tests/capture_owl_gameplay.gd
```

`owl/owl-preview.png` is the Blender studio render; `owl/directions.png` shows the eight shipped directions, and `owl/in-game.png` shows the production enemy in the arena. CI checks materials, geometry, colors, side-view width, the 512 KiB GLB budget, the 96 KiB sprite budget, and the actual ranged attack. The cast builder and gallery also use this geometry.

The top-down game draws the Blender-rendered sprites. Direction 0 faces right and directions advance clockwise in 45-degree steps. Sprite drawing counters the entity rotation, keeping the camera perspective upright. The models do not contain skeletal rigs or baked walk/attack clips; the game applies procedural movement. Elite badges, armour plates/bars, attack warnings, dash trails and shield effects remain live gameplay overlays.

Art and tools have `.gdignore` files so the browser package does not import Blender sources or the large concept sheet. All sprite paths use explicit preloads for reliable exports. Existing scenery is retained.

## Reproduce

Use Blender 5.2 and Godot 4.7.2. Start the model build in a fresh Blender document:

```
blender --background --factory-startup --python tools/build_picnic_assets.py
blender --background art/picnic-cast.blend --python tools/build_picnic_assets.py -- --render
blender --background art/picnic-cast.blend --python tools/prepare_picnic_gallery.py
godot --headless --path . --import
godot --headless --path . --script tests/model_art_test.gd
godot --path . --script tests/model_art_test.gd
godot --path . --script tests/capture_cast_identity.gd
godot --headless --path . --export-release Web build/web/index.html
python tools/serve_preview.py
```

The graphical art test creates the catalog. The preview server supplies the isolation headers required by the threaded browser export at http://127.0.0.1:8765. The scripts resolve the checkout from their own locations. Pass a different port to the preview server when an existing PWA cache is stale: `python tools/serve_preview.py 8766`.

Validation: gameplay smoke suite, fun systems suite, all 94 textures present/nonempty, graphical catalog and gameplay screenshots, local web export and browser interaction.
