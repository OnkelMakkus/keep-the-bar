#tavern.gd
extends NavigationRegion3D

@onready var spawner_marker: Marker3D = $SpawnerMarker
@onready var customer_exit: Marker3D = $Customer_Exit
@onready var look_at_marker: Marker3D = $look_at_marker


func _ready() -> void:
	spawner_marker.global_position.y = 0
	customer_exit.global_position.y = 0
	Signalmanager.set_spawn_marker.emit(spawner_marker)
	Signalmanager.set_customer_exit.emit(customer_exit)
	Signalmanager.set_look_at_marker.emit(look_at_marker)
