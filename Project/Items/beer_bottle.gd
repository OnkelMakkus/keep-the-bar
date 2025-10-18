# beer_bottle.gd (neu)
extends Node3D

# -----------------------------
#  SCENE REFS
# -----------------------------
@export_category("Scene")
@export var mesh: MeshInstance3D

@export_category("VFX / Materials")
@export var outline_mat: ShaderMaterial
@export var teleport_mat: ShaderMaterial
@export var warp_out: AudioStreamPlayer3D
@export var warp_in: AudioStreamPlayer3D

# -----------------------------
#  CONTENT
# -----------------------------
@export_category("Content")
@export var liquid: Liquid              # z.B. res://.../Liquids/beer.tres
@export var volume_ml: int = 500        # „Serviergröße“ (Info/Label)
@export var full: bool = true           # falls du später „geleert“ trackst

# -----------------------------
#  UI / LABEL
# -----------------------------
@export_category("UI")
@export var custom_pickup_hint: String = "<LMB> to pick up"

@export var replicator_item_id: String = ""   # wird vom Replicator gesetzt

# -----------------------------
#  STATE (intern)
# -----------------------------
var _base_mats: Array[Material] = []
var _outlined_mat: Material
var _current_scale: Vector3
var label_name := "Beer\n<LMB> to pick up"

var dirty: bool = false
var current_table: Node = null
var current_index: int = -1


func _ready() -> void:
	# Gruppen für bestehende Logik
	add_to_group("Bottle")
	add_to_group("BeerBottle")
	add_to_group("Pickupable")  # damit dein Pickup-Flow es sicher findet

	_current_scale = scale

	# Materials cachen (für Outline)
	if mesh and mesh.mesh:
		var surf_count := mesh.mesh.get_surface_count()
		for i in range(surf_count):
			_base_mats.append(mesh.mesh.surface_get_material(i))
	if _base_mats.size() > 0 and outline_mat:
		var base_mat: Material = _base_mats[0]
		_outlined_mat = base_mat.duplicate()
		_outlined_mat.next_pass = outline_mat

	# (Optional) Outline-Generator wie bei dir
	Gamemanager.attach_outlineGenerator(self)

	# Teleport-In
	if warp_in:
		warp_in.play()
	if VFX and teleport_mat:
		await VFX.teleport_in(mesh, teleport_mat, 2.0)

	_update_label()


# ------------------------------------------------------------
# Public API (kompatibel zu deinem Flow)
# ------------------------------------------------------------

func place_on_table_by_customer(pos: Vector3, table: Node, index: int) -> void:
	dirty = true
	global_position = pos
	current_table = table
	current_index = index
	_update_label()

func remove_from_table() -> void:
	current_table = null
	current_index = -1

func set_obj_scale() -> void:
	scale = _current_scale

func show_label() -> void:
	_update_label()

func hide_label() -> void:
	# Falls du später ein echtes Label3D nutzt – hier leer lassen
	pass


# ------------------------------------------------------------
# Visual / Label / VFX
# ------------------------------------------------------------
func stop_playing_teleport():
	warp_in.stop()

func teleport_out() -> void:
	if warp_out: warp_out.play()
	if VFX:
		await VFX.teleport_out_owner(self, mesh, teleport_mat, 2.0)

func set_highlight(state: bool) -> void:
	if VFX and _outlined_mat and is_instance_valid(mesh):
		VFX.set_highlight(mesh, _outlined_mat, state)

func _update_label() -> void:
	var beer_name := ""
	if liquid != null:
		beer_name = (liquid.display_name if "display_name" in liquid and liquid.display_name != "" else liquid.id)
	else:
		beer_name = "Beer"
	var dirty_prefix := "Dirty " if dirty else ""
	label_name = "%s%s\n%d ml\n%s" % [dirty_prefix, beer_name, int(volume_ml), custom_pickup_hint]


# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

# Snap-to-Shelf (benutzt deine Utility)
func place_on_shelf(reference_point: Vector3, shelf: MeshInstance3D) -> bool:
	return Gamemanager.place_on_shelf(self, reference_point, shelf)

func despawn() -> void:
	queue_free()
