extends Node3D

signal finished_pouring()

@export var ingredient_name := "Rum"
@export var content_ml := 700.0
@export var max_content_ml := 700.0
@export var liquid_offset := 0.14

var is_pouring := false
var pour_tween: Tween
var current_scale = scale

@onready var fill_indicator: MeshInstance3D = $Cylinder/fill_indicator
@onready var label_3d: Label3D = $Label3D

func _ready() -> void:
	Gamemanager.attach_outlineGenerator(self)
	var material = Gamemanager.INGREDIENTS[ingredient_name]["material"]
	fill_indicator.material_override = material
	fill_indicator.visible = true
	label_3d.visible = false
	_update_visuals()
	_update_label()

func show_label():
	_update_label()
	label_3d.visible = true

func hide_label():
	label_3d.visible = false

func set_obj_scale():
	scale = current_scale

func set_liquid(amount: float):
	content_ml = clamp(amount, 0.0, max_content_ml)
	_update_visuals()
	_update_label()

func remove_liquid(amount: float) -> float:
	var removed = min(amount, content_ml)
	content_ml -= removed
	content_ml = clamp(content_ml, 0.0, max_content_ml)
	_update_visuals()
	_update_label()
	return removed

func try_pour_into(glass: Node3D, amount: float):
	if not is_pouring or content_ml <= 0:
		emit_signal("finished_pouring")
		return
	var poured = remove_liquid(amount)
	if poured > 0 and glass and glass.is_in_group("Glass"):
		glass.add_liquid(ingredient_name, poured)
	if content_ml <= 0 or poured <= 0:
		emit_signal("finished_pouring")

func start_pouring():
	if is_pouring or content_ml <= 0:
		return
	is_pouring = true
	if pour_tween: pour_tween.kill()
	pour_tween = create_tween()
	pour_tween.tween_property(self, "rotation", Vector3(0, 0, deg_to_rad(100)), 0.3)
	pour_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func stop_pouring():
	if not is_pouring:
		return
	is_pouring = false
	if pour_tween: pour_tween.kill()
	pour_tween = create_tween()
	pour_tween.tween_property(self, "rotation", Vector3.ZERO, 0.2)
	pour_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	emit_signal("finished_pouring")

func _update_visuals():
	if max_content_ml > 0:
		var fill_level = content_ml / max_content_ml
		fill_indicator.scale.y = fill_level
		var mesh = fill_indicator.mesh
		if mesh:
			var mesh_height = mesh.get_aabb().size.y
			fill_indicator.position.y = liquid_offset - (1.0 - fill_level) * 0.5 * mesh_height

func _update_label():
	label_3d.text = "%s (%d ml)" % [ingredient_name, int(content_ml)]

# Snap-to-Shelf helper (optional)
func place_on_shelf(reference_point: Vector3, shelf: MeshInstance3D) -> bool:
	return Gamemanager.place_on_shelf(self, reference_point, shelf)
