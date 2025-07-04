extends Marker3D

@onready var is_occupied := false


func set_occupied(value):
	is_occupied = value
	
	
func get_occupied():
	return is_occupied
