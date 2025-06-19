#glas.gd
extends Node3D

@onready var glass_liquid: Node3D = $glass_liquid
@onready var fill_bar := $FillUI/ProgressBar
@onready var fill_ui: Control = $FillUI
@onready var fill_background: ColorRect = $FillUI/ProgressBar2
@onready var label_3d: Label3D = $Label3D

@export var fill_ml := 0.0
@export var max_fill_ml := 250.0
@export var liquid_offset := 0.05

var glass_liquid_mesh: MeshInstance3D
var contents := {}  # z.B. { "Rum": 40.0, "Wasser": 20.0 }

var current_scale = scale

func set_obj_scale():
	scale = current_scale

func _ready():
	Gamemanager.attach_outlineGenerator(self)
	label_3d.text = ""
	glass_liquid_mesh = glass_liquid.get_child(0)
	_update_visuals()
	
func show_label():
	_update_label()
	label_3d.visible = true

func hide_label():
	label_3d.visible = false

func add_liquid(liquid_name: String, amount: float) -> float:
	var total_ml = get_total_fill_ml()
	var available_space = max_fill_ml - total_ml
	var actual_added = min(amount, available_space)
	if actual_added <= 0.0:
		return 0.0
	contents[liquid_name] = (contents.get(liquid_name, 0.0)) + actual_added
	_set_liquid_material(liquid_name)
	_update_visuals()
	_update_label()
	return actual_added

func remove_liquid(liquid_name: String, amount: float) -> float:
	var in_glass = contents.get(liquid_name, 0.0)
	var actual_removed = min(amount, in_glass)
	if actual_removed > 0.0:
		contents[liquid_name] = in_glass - actual_removed
		if contents[liquid_name] <= 0.0:
			contents.erase(liquid_name)
	_update_visuals()
	_update_label()
	return actual_removed	
	

func _set_liquid_material(liquid_name: String):
	var ing = Gamemanager.INGREDIENTS.get(liquid_name)
	if ing:
		var mat = ing.get("material")
		if mat and glass_liquid_mesh:
			glass_liquid_mesh.material_override = mat
			

func get_total_fill_ml() -> float:
	var sum := 0.0
	for v in contents.values():
		sum += v
	return sum

func _update_label():
	if contents.size() == 0:
		label_3d.text = ""
		return
	var text = ""
	for k in contents.keys():
		text += "%s (%d ml)\n" % [k, contents[k]]
	label_3d.text = text.strip_edges()
	

func set_liquid(amount: float):
	fill_ml = clamp(amount, 0.0, max_fill_ml)
	_update_visuals()
	

func _update_visuals():
	var total_ml = get_total_fill_ml()
	var fill_level = total_ml / max_fill_ml if max_fill_ml > 0 else 0.0
	glass_liquid.scale.y = fill_level

	var mesh = glass_liquid_mesh.mesh
	if mesh:
		var mesh_height = mesh.get_aabb().size.y
		glass_liquid.position.y = liquid_offset - (1.0 - fill_level) * 0.5 * mesh_height

# Snap-to-regal bleibt erhalten:
func place_on_shelf(reference_point: Vector3, shelf: MeshInstance3D) -> bool:
	return Gamemanager.place_on_shelf(self, reference_point, shelf)
	
