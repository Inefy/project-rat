# Mouth trap

Original Blender geometry inspired by the user-supplied `reference.png`: a narrow-waisted fleshy mouth with uneven ivory teeth and a tongue at one end. The reference is retained for art direction; it is not a runtime texture.

Open `mouth-trap.blend` in Blender. Two named jaw hinges have editable rotation keyframes on frames 1–42 at 30 fps: open, tense, clamp, hold, reopen. Materials are procedural; no external textures are required.

Rebuild from the repository root:

```sh
blender --background --factory-startup --python tools/mousetrap_model.py
python tools/pack_mousetrap_sprites.py
```

The game uses six transparent rendered poses in `assets/sprites/hazards/mouth_trap.png`, keeping the browser build lightweight. Full-size open and clamped previews are included here.

## Gameplay

- First spawn attempt after 5–8 seconds of combat, then every 10–16 seconds.
- Maximum two traps; spawn away from the rat, other traps, and explosive cans.
- A 0.9-second appearance warning precedes activation.
- Overlapping the mouth with the rat's collision body triggers a red warning for 0.16 seconds, followed by a 0.12-second clamp.
- A bite deals 22 damage (14 in Cozy mode) when the rat overlaps the snapping or closed jaws. Existing dash invulnerability and shields apply. The closed jaws remain dangerous if the initial impact misses or invulnerability expires while the rat stays inside.
- The jaws reopen and recover before another bite; one damage event per clamp.
- After 18 seconds the trap becomes harmless and fades out over 0.65 seconds. Pausing freezes its timers.

Gameplay constants and the animation state machine are in `scripts/mouth_trap.gd`.
