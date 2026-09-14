@tool
extends EditorScenePostImport
## Bake vertex-color materials into the imported scene, including the dark body.

func _post_import(scene: Node) -> Object:
	for part in scene.find_children("*", "MeshInstance3D", true, false):
		for surface in range(part.mesh.get_surface_count()):
			var material: BaseMaterial3D = part.mesh.surface_get_material(surface)
			if material and part.mesh.surface_get_format(surface) & Mesh.ARRAY_FORMAT_COLOR:
				material.vertex_color_use_as_albedo = true
	return scene
