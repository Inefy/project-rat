# Character movement

All ten characters have eight movement poses in eight directions, plus a resting pose. These are rendered in Blender from the existing editable models. Named mesh parts and weighted mesh deformation keep their paint, outlines, skin and eyes attached while they move.

- Rat: alternating steps, swaying tail and trailing scarf.
- Cat: diagonal four-foot gait and blade-tail motion.
- Raccoon: short steps, swinging arm, moving lid and tail.
- Fox: quick steps and a sweeping tail.
- Alpha Cat: long steps, swinging hands, cape and blade-tail motion.
- Junkyard Dog: heavy alternating forepaws and hind feet.
- Bird: asymmetric wingbeats and tucked, moving feet.
- Owl: four wing fans with staggered beats.
- Barn Owl: broad, slower wingbeats and hanging feet.
- Snake: a continuous travelling wave through its body, markings and tongue.

`scripts/character_animation.gd` drives the poses from distance travelled. Faster movement increases step rate; backing up reverses the rat's gait. Birds keep flapping while hovering. Starts, stops, leaning, attack crouches and dash stretches ease into place. Pausing stops every animation with the rest of gameplay.

## Files

- `assets/sprites/movement/*.png`: ten runtime atlases, each 1280 × 1440. Columns are directions, rows 0–7 are movement poses, and row 8 is the resting pose. Each cell is 160 × 160.
- `manifest.json`: atlas dimensions and compressed sizes (about 5.9 MiB total).
- `movement-preview.gif`: Blender pose loops for the whole cast.
- `movement-poses.png`: resting pose and four points in each loop, viewed from the front.
- `movement-runtime.gif`: the actual Godot player/enemy drawing paths with movement pacing and shadows.

## Rebuild

From the project directory:

```sh
blender --background --factory-startup --python-exit-code 1 --python tools/render_movement_sprites.py
python tools/pack_movement_sprites.py
godot --headless --path . --editor --import
```

`godot --path . --script tools/capture_movement_preview.gd` captures the production drawing paths to `build/movement-runtime/` for an in-engine preview. Run the packer again afterwards to assemble `movement-runtime.gif`.

The renderer reads the five reference studios and `art/nightmare-cast/nightmare-cast.blend`. It writes temporary frames under the ignored `build/movement-frames/` directory. `-- --only rat,owl` limits a render to selected characters. Packing requires Python with Pillow and rejects clipped frames. Source studios and static GLBs are preserved; the pose recipe lives in the renderer script.
