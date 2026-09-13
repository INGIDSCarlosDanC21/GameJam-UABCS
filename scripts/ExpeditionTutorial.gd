extends Node3D
# Two real actions, then short hints tied to the thing being looked at.
var step := 0
var _baseline := 0
var _ready_run := false
var _elapsed := 0.0
var _scan_left := 0.0
var _notice_left := 0.0
var _last_depth := 0
var _seen: Dictionary = {}
var _focus: WeakRef
var _card: Node3D
var _label: Label3D
var _arrow: Label3D
var _ring: Node3D
const TIPS := {
	"pez azul": "PEZ AZUL · Mantén clic / gatillo\nCapturar: + monedas, − salud del mar.",
	"pez naranja": "PEZ NARANJA · Captura o deja nadar\nMás grande = más monedas. Limpiar recupera salud.",
	"pez payaso": "PEZ PAYASO · ¡Prueba una fotografía!\nRegistrarlo en el almanaque no lo daña.",
	"pez dorado millonario": "PEZ DORADO · Captura de gran valor\nMantén el puntero y clic / gatillo sobre él.",
	"pez linterna": "PEZ LINTERNA · Desde 12 km\nSu luz lo delata; puedes capturarlo o fotografiarlo.",
	"pez oracles": "ORACLES · Tócalo para ganar tiempo\nRalentiza el mundo 5 s: aprovecha para limpiar.",
	"anginla": "ANGUILA · Evita tocarla\nSe enfada y se electrifica; mejor fotografiarla.",
	"pulpo": "PULPO · Cuidado con la tinta\nTocarlo mancha parte del visor durante 3 s.",
	"foca": "FOCA · ¡Tócala!\n10 s de fiebre: doble dinero y pesca sin daño.",
	"medusa": "MEDUSA · Esquívala\nTocarla paraliza a la mitad de los robots 5 s.",
	"pez globo": "PEZ GLOBO · Aparta el puntero\nTe sigue despacio; tocarlo causa parálisis 2,5 s.",
	"caracol": "CARACOL · Sacude la vista ↔\nUnas 5 veces rápidas, sin forzar el cuello.",
	"ShopFilter": "FILTROBOT · Un residuo por robot\nMientras lo digiere está ocupado. Máximo: 30.",
	"ShopBait": "CEBO · Más peces y mejores recompensas\nMira el precio y tu dinero antes de comprar.",
	"ShopNet": "RED · Mantén clic / gatillo sobre un pez\nCada mejora acorta su captura; no la de basura.",
	"ShopFlashlight": "LINTERNA · Apunta al lugar que quieras iluminar\n5 mejoras de alcance y luz; ahorra para el abismo.",
	"ResearchCamera": "CÁMARA · Agarra con clic / gatillo\nCentra un pez y pulsa otra vez. Soltar: derecho / grip.",
	"trash": "BASURA · Recógela antes de que toque un pez\nA mano: +5 monedas y +salud. Dejarla pasar daña el mar."
}
func _ready() -> void:
	name = "ExpeditionTutorial"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_card = Node3D.new()
	add_child(_card)
	_label = Label3D.new()
	_label.font_size = 30
	_label.pixel_size = .0008
	_label.outline_size = 7
	_label.width = 920
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.no_depth_test = true
	_label.render_priority = 26
	_card.add_child(_label)
	_arrow = Label3D.new()
	_arrow.text = "▼"
	_arrow.font_size = 54
	_arrow.pixel_size = .0015
	_arrow.modulate = Color("ffe3a1")
	_arrow.no_depth_test = true
	add_child(_arrow)
	_ring = Node3D.new()
	add_child(_ring)
	var mesh := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = .88
	torus.outer_radius = 1.0
	torus.rings = 24
	torus.ring_segments = 6
	mesh.mesh = torus
	mesh.rotation.x = PI / 2
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("ffe3a1")
	mat.no_depth_test = true
	mesh.material_override = mat
	_ring.add_child(mesh)
	hide()

func _hint(key: String, text: String, target: Node3D = null) -> void:
	_label.text = text
	_notice_left = 6.0
	_seen[key] = _elapsed
	_focus = weakref(target) if is_instance_valid(target) else null

func _finish_intro() -> void:
	step = 2
	GameManager.tutorial_active = false
	GameManager.sound_requested.emit("objective")
	_hint("start", "¡A EXPLORAR! · Empiezan tus 5 minutos\nLimpia 15 residuos y conserva al menos 70% de salud.")

func _looked_at() -> Node3D:
	# Check both hands; never assign a stale pointer target to a typed variable.
	for path in ["XROrigin3D/LeftController", "XROrigin3D/RightController"]:
		var pointer := get_parent().get_node_or_null(path)
		if not is_instance_valid(pointer): continue
		var candidate = pointer.get("_target")
		if is_instance_valid(candidate) and not candidate.is_queued_for_deletion():
			return candidate
	# Looking is enough, even before the player knows how to aim a controller.
	var camera := get_viewport().get_camera_3d()
	var best: Node3D
	var score := .985
	for candidate in get_tree().get_nodes_in_group("interactable"):
		if not candidate is Node3D or not candidate.is_visible_in_tree(): continue
		if candidate is CollisionObject3D and candidate.collision_layer == 0: continue
		var direction: Vector3 = (candidate.global_position - camera.global_position).normalized()
		var alignment := direction.dot(-camera.global_basis.z)
		if alignment > score:
			best = candidate
			score = alignment
	return best

func _context(target: Node3D) -> void:
	if not is_instance_valid(target): return
	var key := str(target.name)
	if target.is_in_group("trash"): key = "trash"
	elif target.is_in_group("hostiles"):
		key = "caracol" if target.snail else ("medusa" if target.jellyfish else "pez globo")
	elif target.is_in_group("fish") or target.is_in_group("entities"):
		key = str(target.species)
	if not TIPS.has(key): return
	if _seen.has(key) and _elapsed - float(_seen[key]) < 45: return
	_hint(key, TIPS[key], target)

func _process(delta: float) -> void:
	visible = GameManager.mode_selected and GameManager.play_mode == GameManager.PlayMode.EDUCATIONAL and not GameManager.is_run_over() and not get_tree().paused
	if not visible: return
	var camera := get_viewport().get_camera_3d()
	_card.global_transform = camera.global_transform * Transform3D(Basis.IDENTITY, Vector3(-.12, -.24, -1.1))
	_elapsed += delta
	_notice_left = maxf(0, _notice_left - delta)
	if not _ready_run:
		_ready_run = true
		_baseline = GameManager.waste_removed
		_last_depth = GameManager.depth
	_scan_left -= delta
	if _scan_left <= 0 or step < 2:
		_scan_left = .25
		if step == 0:
			var trash: Node3D
			for candidate in get_tree().get_nodes_in_group("trash"):
				if candidate.collision_layer != 0:
					trash = candidate
					break
			_hint("clean", "1/2 · LIMPIA EL RESIDUO SEÑALADO\nApunta y mantén clic / gatillo: +5 monedas y +salud.", trash)
			if GameManager.waste_removed > _baseline:
				step = 1
				GameManager.sound_requested.emit("objective")
		elif step == 1:
			_hint("robot", "2/2 · PULSA EL BOTÓN SEÑALADO\nCompra un robot: recogerá basura mientras tú exploras.", get_parent().get_node("Cabin/ShopFilter"))
			if GameManager.robots_deployed > 0: _finish_intro()
		elif _notice_left <= 0:
			if GameManager.depth != _last_depth:
				_last_depth = GameManager.depth
				_hint("depth", "%d km · NUEVO ECOSISTEMA\nMás profundo = menos luz. Prueba la linterna." % _last_depth, get_parent().get_node("Cabin/ShopFlashlight"))
			elif GameManager.ocean_health <= 50 and not _seen.has("danger"):
				_hint("danger", "SALUD BAJA · Deja de pescar y limpia\nLa basura retirada recupera el mar.")
			else: _context(_looked_at())
	var photo := get_parent().get_node_or_null("ResearchCamera")
	_card.visible = _notice_left > 0 and (photo == null or photo._flash <= 0)
	var target = _focus.get_ref() if _focus != null else null
	var marked := is_instance_valid(target) and _notice_left > 0
	_ring.visible = marked
	_arrow.visible = marked
	if marked:
		var distance: float = camera.global_position.distance_to(target.global_position)
		var radius := clampf(distance * .055, .085, .24)
		_ring.global_position = target.global_position
		_ring.look_at(camera.global_position, Vector3.UP)
		_ring.scale = Vector3.ONE * radius * (1.0 + .08 * sin(_elapsed * 5))
		_arrow.global_position = target.global_position + Vector3(0, radius + .055, 0)
		_arrow.global_basis = camera.global_basis
