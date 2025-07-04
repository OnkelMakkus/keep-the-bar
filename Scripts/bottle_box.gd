#bottle_box.gd
extends Node3D

@export var staticBodies:Array[StaticBody3D]
var size

func _ready() -> void:
	self.add_to_group("Pickupable")
	self.add_to_group("bottle_box")
	self.add_to_group("beer_bottle_box")
	self.PROCESS_MODE_DISABLED
	size = Gamemanager.get_mesh_sizes($Cylinder)
	Gamemanager.attach_outlineGenerator(self)


func deactivate_coliders():
	pass

func activate_coliders():
	pass
