# Reference fox validation

- Built and rendered in Blender 5.2.1 LTS from the supplied image, packed into the editable `.blend`.
- Visually reviewed the studio render, all eight directions, the Blender viewport, and the actual top-down arena capture. Refined muzzle placement to expose the sleepy eyes and removed overlap at the white tail tip.
- Export: 21,766 triangles, 11,021 source vertices, one mesh, three materials, zero textures, 530,576 bytes. Vertex colors and generated LODs survive Godot import.
- Eight distinct 192 x 192 sprites total 180,495 bytes. All sprites pass the shared transparent-margin check. Health bars clear the ears; collision radius remains 24 game units.
- Passed `fox_model_test`, `model_art_test`, `cat_model_test`, `top_down_test`, `smoke_test`, `fun_systems_test`, `playability_test`, `keyboard_aim_test`, and `balance_test` with Godot 4.7.2.
- Created the release Web export. The existing export exclusions keep editable sources and GLBs out of the playable download.
- The source is a single view, so rear anatomy and depth are interpreted. Fine skin and iris details are simplified for the game model; movement uses the existing procedural animation.
