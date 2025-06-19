#beer_bottle.gd
extends Node3D

@onready var label_3d: Label3D = $Label3D
@export var beer_name := "Pils"
@export var volume_ml := 500.0
@export var full := true  # Für später, falls Kunde Flasche leert

var current_scale = scale

func _ready():
	Gamemanager.attach_outlineGenerator(self)
	label_3d.text = beer_name
	label_3d.visible = false

func show_label():
	label_3d.visible = true

func hide_label():
	label_3d.visible = false

# Regal-Snap bleibt erhalten
func place_on_shelf(reference_point: Vector3, shelf: MeshInstance3D) -> bool:
	return Gamemanager.place_on_shelf(self, reference_point, shelf)
	

func set_obj_scale():
	scale = current_scale
