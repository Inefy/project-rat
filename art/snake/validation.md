# Reference snake validation

- Built in Blender 5.2.1 LTS from the supplied snake drawing, preserved in `art/references/snake-design.png` and packed into the editable source. Installed the same model in the cast library and shared recipe.
- Visually reviewed the studio render, eight directional sprites, and production gameplay capture. Refined checker-like markings into continuous crooked brush strokes and projected the cross patches onto the curved body. The coil has depth for head-on views; the opposite eye and rear patches are inferred from the single drawing.
- Final export: 16,788 triangles, 9,976 source vertices, one mesh, three materials, no texture images, 483,200 bytes. MS Paint body/markings export as unlit, while human eyes and fleshy tongue retain shading. Vertex colors and Godot-generated LODs survive import.
- Eight 192 x 192 sprites total 90,399 bytes, 63% smaller than the previous snake set. Every direction is distinct, nonempty, and has transparent margins. Body fill remains exact, undithered green. Sources, references and GLBs are excluded from the website package.
- Passed `snake_model_test`, `model_art_test`, `owl_model_test`, `fox_model_test`, `cat_model_test`, `top_down_test`, `smoke_test`, `fun_systems_test`, `playability_test`, `keyboard_aim_test`, and `balance_test` with Godot 4.7.2.
- Verified wave-four spawning, the 20-unit collision radius, a visible warning before a single aimed venom shot, attack cooldown reset, and retreat when approached. The taller sprite frame and raised health bar are applied to the production enemy.
- Created the release Web export and checked browser startup and Play interaction. Snake appearance and combat were checked in the native production scene and regression tests. `in-game.png` is a staged arena capture using real enemies and overlays.
- The source model is static, without an armature or animation clips; the game supplies procedural movement, bounce, squash and attack warnings.
