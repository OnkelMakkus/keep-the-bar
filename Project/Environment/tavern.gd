#tavern.gd
extends NavigationRegion3D

@export var spawner_marker: Marker3D
@export var customer_exit: Marker3D
@export var look_at_marker: Marker3D
@export var first_exit_marker: Marker3D


func _ready() -> void:
	spawner_marker.global_position.y = 0
	customer_exit.global_position.y = 0
	Signalmanager.set_spawn_marker.emit(spawner_marker)
	Signalmanager.set_customer_exit.emit(customer_exit)
	Signalmanager.set_look_at_marker.emit(look_at_marker)
	Signalmanager.set_first_exit_marker.emit(first_exit_marker)
