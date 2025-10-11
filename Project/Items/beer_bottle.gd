#beer_bottle.gd
extends Node3D

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
	
func despawn():
	teleport.start(mesh, teleport.scale, self, true)
