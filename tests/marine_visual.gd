extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	var camera := Camera3D.new()
	camera.position=Vector3(0,1.4,5)
	scene.add_child(camera)
	var light := DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-40,-30,0)
	scene.add_child(light)
	var paths := ["reef/fish/Fish1.fbx","reef/fish/Fish2.fbx","reef/fish/Fish3.fbx","marine/Octopus.glb","marine/Seal.glb","marine/Jellyfish.glb"]
	for index in paths.size():
		var model: Node3D=load("res://assets/models/"+paths[index]).instantiate()
		var bounds := AABB()
		var first := true
		for mesh in model.find_children("*","MeshInstance3D",true,false):
			var pose: Transform3D=mesh.transform
			var parent: Node=mesh.get_parent()
			while parent is Node3D:
				pose=parent.transform*pose
				parent=parent.get_parent()
			var box: AABB=pose*mesh.get_aabb()
			bounds=box if first else bounds.merge(box)
			first=false
		var factor:=1.25/maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))
		model.scale=Vector3.ONE*factor
		model.position=Vector3((index%3-1)*2,2.1-int(index/3)*1.7,0)-bounds.get_center()*factor
		scene.add_child(model)
		var label:=Label3D.new()
		label.text=str(index)+": "+paths[index].get_file()
		label.font_size=32
		label.pixel_size=.003
		label.position=Vector3((index%3-1)*2,1.35-int(index/3)*1.7,.1)
		scene.add_child(label)
	await create_timer(2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/marine-models.png")
	quit()
