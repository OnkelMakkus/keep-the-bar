#theke.gd
extends Node3D

@export var theke_marker: Marker3D 
@export var bottle_grid: Node3D 
@export var glass_grid: Node3D 
@export var waiting_slot_01: Marker3D 
@export var waiting_slot_02: Marker3D 

var label_name = "Theke"


func _ready() -> void:
	theke_marker.global_position.y = 0.0
	Signalmanager.set_waiting_marker_01.emit(waiting_slot_01)
	await get_tree().process_frame
	Signalmanager.set_waiting_marker_02.emit(waiting_slot_02)
	await get_tree().process_frame
	Signalmanager.set_theke_marker.emit(theke_marker)
	
	for n in get_tree().get_nodes_in_group("abstell_marker"):
		if n is Marker3D:
			Gamemanager.abstell_marker.append(n)
	
	for n in get_tree().get_nodes_in_group("serving_marker"):
		if n is Marker3D:
			Gamemanager.serving_marker.append(n)
			
	for n in get_tree().get_nodes_in_group("bottle_marker"):
		if n is Marker3D:
			Gamemanager.bottle_marker.append(n)
