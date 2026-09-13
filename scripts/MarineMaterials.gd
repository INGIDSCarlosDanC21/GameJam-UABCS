extends RefCounted
## Preserve all imported texture slots; never flatten a multi-material fish.
static var _world_materials: Dictionary = {}
static var _preview_materials: Dictionary = {}
static func prepare(root: Node3D, preview: bool = false) -> void:
	var cache: Dictionary = _preview_materials if preview else _world_materials
	for mesh in root.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh == null: continue
		for surface in mesh.mesh.get_surface_count():
			var source: Material = mesh.get_active_material(surface)
			if not source is StandardMaterial3D: continue
			if not cache.has(source):
				var prepared := source.duplicate() as StandardMaterial3D
				prepared.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				prepared.roughness=maxf(.55,prepared.roughness)
				prepared.metallic=0.0
				if preview:
					prepared.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
					prepared.no_depth_test=true
					prepared.render_priority=25
				cache[source]=prepared
				cache[prepared]=prepared
			var material: StandardMaterial3D = cache[source]
			mesh.set_surface_override_material(surface,material)
		mesh.material_override=null
