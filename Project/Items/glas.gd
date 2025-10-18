# glass.gd (neu)
extends Node3D

# --- Scene References ---
@export var glass_liquid: Node3D
@export var mesh: MeshInstance3D
@export var warp_out: AudioStreamPlayer3D
@export var warp_in: AudioStreamPlayer3D

# --- Materials / VFX ---
@export var outline_mat: ShaderMaterial
@export var teleport_mat: ShaderMaterial
var _base_mat: Material
var _outlined_mat: Material
var _glass_liquid_mesh: MeshInstance3D

# --- Fill / Contents ---
@export var max_fill_ml: float = 250.0
@export var liquid_offset: float = 0.05
@export var replicator_item_id: String = ""

# WICHTIG: Keys jetzt String-IDs, nicht Liquid-Instanzen!
var contents: Dictionary = {}  # { String(liquid_id) : float ml }
var dirty := false

# --- UI/Label / Misc ---
var label_name := "Glass\n<LMB> to pick up"
var _current_scale := Vector3.ONE
var _size := Vector3.ZERO

var current_table: Node = null
var current_index: int = -1

func _ready() -> void:
	add_to_group("Glass")

	_current_scale = scale
	_base_mat = mesh.get_active_material(0)
	if _base_mat:
		_outlined_mat = _base_mat.duplicate()
		_outlined_mat.next_pass = outline_mat

	var cyl := get_node_or_null("Cylinder") as MeshInstance3D
	if cyl:
		_size = Gamemanager.get_mesh_sizes(cyl)

	if glass_liquid and glass_liquid.get_child_count() > 0:
		_glass_liquid_mesh = glass_liquid.get_child(0) as MeshInstance3D

	glass_liquid.visible = false
	
	if warp_in:
		warp_in.play()
	if VFX and teleport_mat:
		await VFX.teleport_in(mesh, teleport_mat, 2.0)
	
	_update_visuals()

# ---------- Public API ----------
func set_obj_scale() -> void:
	scale = _current_scale

func throw(direction: Vector3, force := 10.0) -> void:
	self.linear_velocity = direction.normalized() * force
	self.angular_velocity = Vector3(randf()*10.0, randf()*10.0, randf()*10.0)

func show_label() -> void:
	_update_label()

func place_on_table_by_customer(pos: Vector3, table: Node, index: int) -> void:
	dirty = true
	current_table = table
	current_index = index
	global_position = pos
	_update_label()

func remove_from_table() -> void:
	current_table = null
	current_index = -1

# ---------- Contents ----------
func add_liquid(liq: Liquid, amount: float) -> float:
	if liq == null or amount <= 0.0:
		return 0.0
	var total_ml := get_total_fill_ml()
	var free_space := max_fill_ml - total_ml
	var add = min(amount, free_space)
	if add <= 0.0:
		return 0.0
	var lid := liq.id
	contents[lid] = float(contents.get(lid, 0.0)) + add
	_set_liquid_material(liq)
	_update_visuals(); _update_label()
	return add

func add_liquid_by_id(liquid_id: String, amount: float) -> float:
	var liq := DrinkDB.get_liquid(liquid_id)
	if liq == null:
		return 0.0
	return add_liquid(liq, amount)

func remove_liquid(liq: Liquid, amount: float) -> float:
	if liq == null or amount <= 0.0:
		return 0.0
	var lid := liq.id
	var in_glass := float(contents.get(lid, 0.0))
	var rem = min(amount, in_glass)
	if rem > 0.0:
		contents[lid] = in_glass - rem
		if contents[lid] <= 0.0:
			contents.erase(lid)
	_update_visuals(); _update_label()
	return rem
	

func get_ml(liq: Liquid) -> int:
	return int(contents.get(liq.id, 0.0))
	

func get_ml_by_id(liquid_id: String) -> int:
	return int(contents.get(liquid_id, 0.0))
	

func get_total_fill_ml() -> float:
	var s := 0.0
	for v in contents.values(): s += float(v)
	return s

# ---------- Visuals / Label ----------
func _set_liquid_material(liq: Liquid) -> void:
	if _glass_liquid_mesh == null: return

	if "material" in liq and liq.material:
		_glass_liquid_mesh.material_override = liq.material
		return

	if typeof(Resourcemanager) != TYPE_NIL and Resourcemanager.INGREDIENTS.has(liq.id):
		var ing = Resourcemanager.INGREDIENTS[liq.id]
		if ing and ing.has("material") and ing.material:
			_glass_liquid_mesh.material_override = ing.material

func _update_visuals() -> void:
	var total_ml := get_total_fill_ml()
	var fill_level := (total_ml / max_fill_ml) if max_fill_ml > 0.0 else 0.0
	fill_level = clamp(fill_level, 0.0, 1.0)

	if glass_liquid:
		glass_liquid.visible = true
		glass_liquid.scale.y = fill_level
		if _glass_liquid_mesh and _glass_liquid_mesh.mesh:
			var mesh_h := _glass_liquid_mesh.mesh.get_aabb().size.y
			glass_liquid.position.y = liquid_offset - (1.0 - fill_level) * 0.5 * mesh_h

	_update_label()

func _update_label() -> void:
	if contents.size() == 0:
		label_name = ("%sGlass\n<LMB> to pick up" % ("Dirty " if dirty else ""))
		return
	var lines: Array[String] = []
	for lid in contents.keys():
		var liq: Liquid = DrinkDB.get_liquid(String(lid))
		var lbl_name := (liq.display_name if liq and liq.display_name != "" else (liq.id if liq else String(lid)))
		lines.append("%s (%d ml)" % [lbl_name, int(contents[lid])])
	label_name = ("%sGlass\n" % ("Dirty " if dirty else "")) + "\n".join(lines) + "\n<LMB> to pick up"

# ---------- Interop / VFX ----------
func stop_playing_teleport():
	warp_in.stop()

func teleport_out() -> void:
	glass_liquid.visible = false
	if warp_out: warp_out.play()
	if VFX:
		await VFX.teleport_out_owner(self, mesh, teleport_mat, 2.0)

func set_highlight(state: bool) -> void:
	if VFX and _outlined_mat and is_instance_valid(mesh):
		VFX.set_highlight(mesh, _outlined_mat, state)

func let_it_fall(fall_position: Vector3) -> void:
	await get_tree().physics_frame
	global_position = fall_position

func place_on_shelf(reference_point: Vector3, shelf: MeshInstance3D) -> bool:
	return Gamemanager.place_on_shelf(self, reference_point, shelf)
