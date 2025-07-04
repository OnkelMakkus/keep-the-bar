#theke.gd
extends Node3D

@onready var theke_marker: Marker3D = $ThekeMarker
@onready var bottle_grid: Node3D = $BottleGrid
@onready var glass_grid: Node3D = $GlassGrid
@onready var waiting_slot_01: Marker3D = $WaitingSlot01
@onready var waiting_slot_02: Marker3D = $WaitingSlot02

var label_name = "Theke"


func _ready() -> void:
	theke_marker.global_position.y = 0.0
	Signalmanager.set_waiting_marker_01.emit(waiting_slot_01)
	await get_tree().process_frame
	Signalmanager.set_waiting_marker_02.emit(waiting_slot_02)
	await get_tree().process_frame
	Signalmanager.set_theke_marker.emit(theke_marker)

func free_slot_for_object(obj: Node3D):
	var grids = [
		"theke/BottleGrid",  # Falls du das mit /root/... brauchst, passe es unten an
		"theke/GlassGrid"
	]
	for path in grids:
		var grid = get_node_or_null(path)
		if grid:
			for slot in grid.get_children():
				if slot is Marker3D and slot.global_position.distance_to(obj.global_position) < 0.01:
					slot.belegt = false
	
	# Für Regal-Slots:
	if obj.get_parent() and obj.get_parent().is_in_group("Regalbrett"):
		for slot in obj.get_parent().get_children():
			if slot is Marker3D and slot.global_position.distance_to(obj.global_position) < 0.01:
				slot.set_meta("belegt", false)
