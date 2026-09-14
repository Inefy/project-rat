# Reference owl validation

- Built in Blender 5.2.1 LTS from the supplied four-wing owl drawing. The reference is preserved and packed into the editable source.
- Visually reviewed the studio, Blender viewport, all eight sprite facings, and gameplay capture. Rounded the feather ends and angled the upper/lower fans in depth to prevent edge-on disappearance.
- Final export: 17,708 triangles, 10,574 source vertices, one mesh, two materials, no texture images, 489,152 bytes. MS Paint fill exports as unlit; the human navel retains shaded folds. Vertex colors and Godot-generated LODs survive import.
- Eight 192 x 192 sprites total 95,780 bytes. All directions have transparent margins and a visible wingspan. PNG render metadata is removed without changing pixels or color-profile information. Source models and references are excluded from the website download.
- Passed `owl_model_test`, `model_art_test`, `fox_model_test`, `cat_model_test`, `top_down_test`, `smoke_test`, `fun_systems_test`, `playability_test`, `keyboard_aim_test`, and `balance_test` with Godot 4.7.2. Rechecked the owl and sprite framing after the final wing adjustment.
- Verified the wave-three owl introduction, attack windup, three-feather spread, cooldown and unchanged collision radius. Barn Owl stays a separate boss.
- Created the release Web export. The source is static; the game supplies procedural motion. Unseen rear anatomy and wing depth are interpreted from the drawing.
