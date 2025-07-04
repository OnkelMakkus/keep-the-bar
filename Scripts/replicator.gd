extends Node3D

@export var REPLICATOR_UI: PackedScene

var label_name := "Replicator\n<E> to open Menu"

func open_ui():
	var rep_ui = REPLICATOR_UI.instantiate()	
	add_child(rep_ui)
	Gamemanager.replicator_open = true
