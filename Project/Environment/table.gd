#table.gd
extends Node3D

var standing_marker: Array[Marker3D] = []

@export_category("Glas Marker")
@export var glas_marker01 : Marker3D
@export var glas_marker02 : Marker3D
@export var glas_marker03 : Marker3D
@export var glas_marker04 : Marker3D

@export_category("Standing Marker")
@export var standing_marker01 : Marker3D
@export var standing_marker02 : Marker3D
@export var standing_marker03 : Marker3D
@export var standing_marker04 : Marker3D

@export var LookAt_Marker: Marker3D

func _ready() -> void:
	add_to_group("Table")
	for n in get_tree().get_nodes_in_group("abstell_marker"):
		if n is Marker3D:
			Gamemanager.abstell_marker.append(n)
