# Reference fox validation

- Built and rendered in Blender 5.2.1 LTS from the supplied image, packed into the editable `.blend`.
- Visually reviewed the studio render, all eight directions, the Blender viewport, and the actual top-down arena capture. Refined the body into flat MS Paint fill with uneven white brush strokes, while keeping shaded human ears and tired eyes.
- Export: 12,698 triangles, 6,487 source vertices, one mesh, three materials, zero textures, 313,748 bytes. Vertex colors and generated LODs survive Godot import.
- The paint material exports as `KHR_materials_unlit`; the skin and eyes retain per-pixel shading. Exact orange pixels are checked after import. Disabling render dithering and denoising removes noise from the flat color fields; PNG compression is lossless. The sprites are 76% smaller than the original shaded revision, and geometry is reduced by 42%.
- Eight distinct 192 x 192 sprites total 43,777 bytes. All sprites pass the shared transparent-margin check. Health bars clear the ears; collision radius remains 24 game units.
- Passed `fox_model_test`, `model_art_test`, `cat_model_test`, `top_down_test`, `smoke_test`, `fun_systems_test`, `playability_test`, `keyboard_aim_test`, and `balance_test` with Godot 4.7.2.
- Created the release Web export. The existing export exclusions keep editable sources and GLBs out of the playable download.
- The source is a single view, so rear anatomy and depth are interpreted. Fine skin and iris details are simplified for the game model; movement uses the existing procedural animation.
