#beer_bottle.gd
extends Node3D

@export var staticBodies:Array[StaticBody3D]
@export var mesh: MeshInstance3D 
@export var liquid: MeshInstance3D 
@export var teleport: Node3D

@export var beer_name := "Pils"
@export var volume_ml := 500.0
@export var full := true  # Für später, falls Kunde Flasche leert
@export var ingredient_name := "Beer"

var current_scale = scale
var size

var dirty := false
var current_table
var current_index

var label_name := "Beer\n<E> to pick up"

func _ready():
	size = Gamemanager.get_mesh_sizes($"Círculo_004")
	teleport.scale =Vector3(70.0, 10.0, 70.0)
	teleport.start(mesh, teleport.scale, self, false)
	Gamemanager.attach_outlineGenerator(self)
	
func show_label():
	pass
	#label_3d.visible = true

func hide_label():	
	pass
	#label_3d.visible = false

# Regal-Snap bleibt erhalten
func place_on_shelf(reference_point: Vector3, shelf: MeshInstance3D) -> bool:
	return Gamemanager.place_on_shelf(self, reference_point, shelf)
	

func set_obj_scale():
	scale = current_scale


func activate_coliders():
	if staticBodies:
		for body in staticBodies:
			body.collision_layer = 1
			body.collision_mask = 1
			for child in body.get_children():
				if child is CollisionShape3D:
					child.disabled = false
	

func deactivate_coliders():
	if staticBodies:
		for body in staticBodies:
			body.collision_layer = 0
			body.collision_mask = 0
			for child in body.get_children():
				if child is CollisionShape3D:
					child.disabled = true


func let_it_fall(position):
	await get_tree().physics_frame
	global_position = position
	activate_coliders()
	
	
func place_on_table_by_customer(pos, table, index):
	dirty = true
	liquid.visible = false
	global_position = pos
	current_table = table
	current_index = index
	label_name = "Empty beer bottle"
	
	
func despawn():
	teleport.start(mesh, teleport.scale, self, true)
