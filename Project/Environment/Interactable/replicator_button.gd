extends MeshInstance3D

@export var REPLICATOR_UI: PackedScene
@export var replicator_marker: Marker3D

var label_name := "Replicator\n<E> to open Menu"

func open_ui():
	var rep_ui = REPLICATOR_UI.instantiate()	
	add_child(rep_ui)
	rep_ui.set_replicator_marker(replicator_marker)
	Gamemanager.replicator_open = true
