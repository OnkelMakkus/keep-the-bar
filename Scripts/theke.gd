#theke.gd
extends Node3D

@onready var theke_marker: Marker3D = $ThekeMarker
@onready var bottle_grid: Node3D = $BottleGrid
@onready var glass_grid: Node3D = $GlassGrid


func _ready() -> void:
	theke_marker.global_position.y = 0.0
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
