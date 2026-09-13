extends RefCounted
static var _entries: Array = []
static func entries() -> Array:
	if _entries.is_empty(): _entries = JSON.parse_string(FileAccess.get_file_as_string("res://assets/almanac/catalog.json"))
	return _entries
static func identify(target: Node) -> String:
	if not is_instance_valid(target) or target.is_queued_for_deletion(): return ""
	if target.has_meta("photo_species"): return str(target.get_meta("photo_species"))
	if target.is_in_group("entities") or target.is_in_group("fish"):
		return str(target.species) if target.kind != 1 and not target._clicked else ""
	if target.is_in_group("hostiles"):
		return "caracol" if target.snail else ("medusa" if target.jellyfish else "pez globo")
	return ""
static func model(index: int) -> Node3D:
	var root := Node3D.new()
	var models := {0:"../../marine/BlueTang.glb",1:"../../marine/Goldfish.glb",2:"../../marine/Eel.glb",3:"../../marine/Anglerfish.glb",4:"../../marine/Goldfish.glb",5:"../../marine/Octopus.glb",7:"../../marine/Seal.glb",8:"../../marine/Snail.glb",9:"../../marine/Jellyfish.glb",10:"../../marine/Puffer.glb",11:"Dolphin.fbx",12:"Shark.glb",13:"../../marine/Octopus.glb",14:"Whale.glb",15:"Manta ray.fbx",16:"../../marine/Octopus.glb",17:"../../marine/Clownfish.glb"}
	if models.has(index):
		var source: Node3D = load("res://assets/models/reef/fish/"+models[index]).instantiate()
		root.add_child(source)
		preload("res://scripts/MarineMaterials.gd").prepare(source)
		var bounds := AABB()
		var first := true
		for mesh in source.find_children("*","MeshInstance3D",true,false):
			var pose: Transform3D = mesh.transform
			var parent: Node = mesh.get_parent()
			while parent is Node3D and parent != root:
				pose = parent.transform * pose
				parent = parent.get_parent()
			var box: AABB = pose * mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
		var factor := .8/maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))
		source.scale *= factor
		source.position -= bounds.get_center()*factor
		return root
	root.free()
	return null
static func part(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1
	mesh.height = 2
	mesh.radial_segments = 12
	mesh.rings = 6
	node.mesh = mesh
	node.position = at
	node.scale = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = .7
	node.material_override = mat
	parent.add_child(node)
	return node
