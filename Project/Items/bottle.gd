# bottle.gd (neu)
extends Node3D

signal finished_pouring()

# --- Scene Refs ---
@export var mesh: MeshInstance3D
@export var warp_out: AudioStreamPlayer3D
@export var warp_in: AudioStreamPlayer3D
@export var fill_indicator: MeshInstance3D
@export var label_3d: Label3D

# --- VFX/Materials ---
@export var outline_mat: ShaderMaterial
@export var teleport_mat: ShaderMaterial
var _base_mat: Material
var _outlined_mat: Material

# --- Inhalt (Resource) ---
@export var liquid: Liquid
@export var volume_ml: float = 700.0
@export var max_volume_ml: float = 700.0
@export var liquid_offset: float = 0.14
@export var is_beer_bottle: bool = false
@export var replicator_item_id: String = ""

# --- State ---
var is_pouring := false
var pour_tween: Tween
var _current_scale := Vector3.ONE
var label_name := "Bottle"

func _ready() -> void:
	add_to_group("Bottle")
	if is_beer_bottle:
		add_to_group("BeerBottle")

	_current_scale = scale

	_base_mat = mesh.get_active_material(0)
	if _base_mat:
		_outlined_mat = _base_mat.duplicate()
		_outlined_mat.next_pass = outline_mat

	_apply_liquid_material()

	if label_3d:
		label_3d.visible = false
	if fill_indicator:
		fill_indicator.visible = false

	if warp_in: warp_in.play()
	if VFX and teleport_mat:
		await VFX.teleport_in(mesh, teleport_mat, 2.0)

	_update_visuals()
	_update_label()

# ---------- Gießen ----------
func start_pouring() -> void:
	if is_pouring or volume_ml <= 0.0: return
	is_pouring = true
	if pour_tween: pour_tween.kill()
	pour_tween = create_tween()
	pour_tween.tween_property(self, "rotation", Vector3(0,0,deg_to_rad(100)), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func stop_pouring() -> void:
	if not is_pouring: return
	is_pouring = false
	if pour_tween: pour_tween.kill()
	pour_tween = create_tween()
	pour_tween.tween_property(self, "rotation", Vector3.ZERO, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	emit_signal("finished_pouring")

func try_pour_into(glass: Node3D, amount: float) -> void:
	if not is_pouring or volume_ml <= 0.0 or glass == null:
		emit_signal("finished_pouring"); return
	if "dirty" in glass and glass.dirty:
		emit_signal("finished_pouring"); return

	var poured := remove_liquid(amount)
	if poured > 0.0 and glass.is_in_group("Glass") and glass.has_method("add_liquid"):
		glass.add_liquid(liquid, poured)

	if volume_ml <= 0.0 or poured <= 0.0:
		emit_signal("finished_pouring")

# ---------- Inhalt / Visuals ----------
func set_obj_scale() -> void:
	scale = _current_scale

func set_liquid(amount: float) -> void:
	volume_ml = clampf(amount, 0.0, max_volume_ml)
	_update_visuals(); _update_label()

func remove_liquid(amount: float) -> float:
	if amount <= 0.0: return 0.0
	var removed := minf(amount, volume_ml)
	volume_ml = clampf(volume_ml - removed, 0.0, max_volume_ml)
	_update_visuals(); _update_label()
	return removed

func _update_visuals() -> void:
	if not fill_indicator: return
	var fill_level := 0.0
	if max_volume_ml > 0.0:
		fill_level = clampf(volume_ml / max_volume_ml, 0.0, 1.0)
	fill_indicator.scale.y = fill_level
	var vis_mesh := fill_indicator.mesh
	if vis_mesh:
		var mesh_height := vis_mesh.get_aabb().size.y
		fill_indicator.position.y = liquid_offset - (1.0 - fill_level) * 0.5 * mesh_height

func _update_label() -> void:
	var liq_name := (liquid.display_name if liquid and "display_name" in liquid and liquid.display_name != "" else (liquid.id if liquid else "Unknown"))
	label_name = "%s\n%d ml\n<LMB> to pick up" % [liq_name, int(volume_ml)]
	if label_3d:
		label_3d.text = label_name

func _apply_liquid_material() -> void:
	if not fill_indicator: return
	if liquid and "material" in liquid and liquid.material:
		fill_indicator.material_override = liquid.material
		return
	# Fallback auf altes Register nur falls noch vorhanden
	if liquid and typeof(Resourcemanager) != TYPE_NIL and Resourcemanager.INGREDIENTS.has(liquid.id):
		var ing = Resourcemanager.INGREDIENTS[liquid.id]
		if ing and ing.has("material") and ing.material:
			fill_indicator.material_override = ing.material

# ---------- VFX / Helpers ----------
func stop_playing_teleport():
	warp_in.stop()

func teleport_out() -> void:
	if warp_out: warp_out.play()
	if VFX:
		await VFX.teleport_out_owner(self, mesh, teleport_mat, 2.0)

func set_highlight(state: bool) -> void:
	if VFX and _outlined_mat and is_instance_valid(mesh):
		VFX.set_highlight(mesh, _outlined_mat, state)

func place_on_shelf(reference_point: Vector3, shelf: MeshInstance3D) -> bool:
	return Gamemanager.place_on_shelf(self, reference_point, shelf)

func despawn() -> void:
	queue_free()
