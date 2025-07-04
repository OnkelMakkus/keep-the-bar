#table.gd
extends Node3D

var glass_markers : Array [Dictionary]
var standing_markers : Array [Dictionary]

var marker_pairs: Array = []

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

func _ready() -> void:
	add_to_group("Table")

	var glass_marker_list = [glas_marker01, glas_marker02, glas_marker03, glas_marker04]
	var standing_marker_list = [standing_marker01, standing_marker02, standing_marker03, standing_marker04]

	for i in glass_marker_list.size():
		marker_pairs.append({
			"glass_marker": glass_marker_list[i],
			"standing_marker": standing_marker_list[i],
			"used": false
		})
	
func get_free_marker_pair():
	for i in marker_pairs.size():
		if not marker_pairs[i]["used"]:
			return {"table": self, "index": i, "glass_marker": marker_pairs[i]["glass_marker"], "standing_marker": marker_pairs[i]["standing_marker"]}
	return {}
