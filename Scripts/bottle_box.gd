extends Node3D

func _ready() -> void:
	self.add_to_group("Pickupable")
	Gamemanager.attach_outlineGenerator(self)
