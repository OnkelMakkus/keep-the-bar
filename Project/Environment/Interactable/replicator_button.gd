extends MeshInstance3D

@export var REPLICATOR_UI: PackedScene
#@export var replicator_marker1: Marker3D
#@export var replicator_marker2: Marker3D
#@export var replicator_marker3: Marker3D
#@export var replicator_marker4: Marker3D
#@export var replicator_marker5: Marker3D
#@export var replicator_marker6: Marker3D
#@export var replicator_marker7: Marker3D

var label_name := "Replicator\n<E> to open Menu"

func open_ui():
	var rep_ui = REPLICATOR_UI.instantiate()
	add_child(rep_ui)
	#rep_ui.set_replicator_marker(replicator_marker1,replicator_marker2,
	#replicator_marker3,replicator_marker4, replicator_marker5,
	#replicator_marker6, replicator_marker7)
	Gamemanager.replicator_open = true
