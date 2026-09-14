# Cat integration on latest main

Base: `3db853f` (pulled from `origin/main`). The game now uses the top-down camera, independent movement and cursor/arrow-key aiming.

- The reference cat uses eight 192 x 192 Blender-rendered directions: 225,979 source PNG bytes total. Full authored sprite colors are retained for visibility against the dark garden.
- The editable Blender source and GLB exports remain available. GLB: 416,440 bytes, 16,381 triangles, three materials, one mesh, no textures. Vertex colors and green eye emission survive import.
- The top-down web package excludes unused 3D models and first-person scripts.
- Passed: top-down camera/combat/pause/restart, cat model/sprite budget, gameplay smoke, fun systems, playability, keyboard aiming, sprite art, balance, boss phases and feedback suites.
- `light_trail_test.gd` still fails its existing "dashes leave an unbroken trail" assertion. This was also reproduced on a clean checkout of `3db853f` before the view change. The unrelated test and trail implementation were left unchanged.
- Web release export succeeded (2,184,652-byte game data package, plus the Godot runtime). The browser was verified at the TOP-DOWN menu, then in live play with arrow aiming, firing, enemies and pause. A fresh port avoids the previous FPS service-worker cache. `in-game.png` is a graphical Godot capture of the production cat sprites in the top-down arena.

Local preview: http://127.0.0.1:8769/. No public deployment was performed.
